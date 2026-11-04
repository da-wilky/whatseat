package main

import (
	"context"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"net/netip"
	"regexp"
	"strings"
	"sync"
	"time"
)

type limits struct {
	maxAccounts    int
	maxBackups     int
	maxBackupBytes int64
	inviteOnly     bool
	// Zero keeps accounts forever.
	inactiveDays int
	// New accounts per hour per client address.
	registerPerHour int
	// Set by the reverse proxy to the client's address, which the connection only shows as the proxy's.
	// Empty uses the connection's address.
	clientIPHeader string
}

// Uploads are held in memory until stored, and storing is serialised; this bounds the memory they take.
// Each account gets at most one, so a single slow client can't take all of them.
const maxConcurrentUploads = 4

// info is public, so the app can warn about deletion and ask for an invite before registering.
type info struct {
	InactiveDays int  `json:"inactiveDays"`
	InviteOnly   bool `json:"inviteOnly"`
}

type api struct {
	store   *store
	limits  limits
	uploads chan struct{}

	mu            sync.Mutex
	registrations map[string][]time.Time
	uploading     map[string]bool
}

var (
	accountPattern = regexp.MustCompile(`^[0-9a-f]{32}$`)
	// The optional suffix tells apart backup series of separate setups.
	namePattern = regexp.MustCompile(`^whatseat-backup-\d{4}-\d{2}-\d{2}(-[0-9a-f]{8})?\.json$`)
)

type ctxKey struct{}

func newAPI(s *store, l limits) http.Handler {
	a := &api{
		store:         s,
		limits:        l,
		uploads:       make(chan struct{}, maxConcurrentUploads),
		registrations: map[string][]time.Time{},
		uploading:     map[string]bool{},
	}
	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, r *http.Request) { w.WriteHeader(http.StatusNoContent) })
	mux.HandleFunc("GET /v1/info", a.info)
	mux.HandleFunc("POST /v1/register", a.register)
	mux.HandleFunc("POST /v1/ping", a.authed(a.info))
	mux.HandleFunc("DELETE /v1/account", a.authed(a.deleteAccount))
	mux.HandleFunc("GET /v1/backups", a.authed(a.list))
	mux.HandleFunc("GET /v1/backups/{name}", a.authed(a.named(a.read)))
	mux.HandleFunc("PUT /v1/backups/{name}", a.authed(a.named(a.write)))
	mux.HandleFunc("DELETE /v1/backups/{name}", a.authed(a.named(a.delete)))
	return mux
}

// credentials reads "Bearer <account>.<token>"; both are derived from the recovery code by the app.
func credentials(r *http.Request) (account string, tokenHash []byte, ok bool) {
	value, found := strings.CutPrefix(r.Header.Get("Authorization"), "Bearer ")
	if !found {
		return "", nil, false
	}
	account, encoded, found := strings.Cut(value, ".")
	token, err := base64.RawURLEncoding.DecodeString(encoded)
	if !found || err != nil || len(token) != 32 || !accountPattern.MatchString(account) {
		return "", nil, false
	}
	// The token is 256 random bits, so a plain hash is enough: there is nothing to brute-force.
	hash := sha256.Sum256(token)
	return account, hash[:], true
}

func internalError(w http.ResponseWriter, err error) {
	log.Print(err)
	http.Error(w, "internal error", http.StatusInternalServerError)
}

func (a *api) info(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(info{a.limits.inactiveDays, a.limits.inviteOnly})
}

// inviteHash accepts the code as typed: any case, with or without separators.
func inviteHash(code string) []byte {
	normalized := strings.Map(func(r rune) rune {
		switch {
		case r >= 'a' && r <= 'z':
			return r - 'a' + 'A'
		case r >= 'A' && r <= 'Z', r >= '0' && r <= '9':
			return r
		}
		return -1
	}, code)
	hash := sha256.Sum256([]byte(normalized))
	return hash[:]
}

func (a *api) register(w http.ResponseWriter, r *http.Request) {
	account, hash, ok := credentials(r)
	if !ok {
		http.Error(w, "bad credentials", http.StatusUnauthorized)
		return
	}
	if a.answerExisting(w, r, account, hash) {
		return
	}
	client, err := a.clientAddress(r)
	if err != nil {
		internalError(w, err)
		return
	}
	if !a.allowRegistration(client, time.Now()) {
		w.Header().Set("Retry-After", "3600")
		http.Error(w, "too many new accounts, try again later", http.StatusTooManyRequests)
		return
	}
	var invite []byte
	if a.limits.inviteOnly {
		var body struct {
			Invite string `json:"invite"`
		}
		if err := json.NewDecoder(http.MaxBytesReader(w, r.Body, 1<<10)).Decode(&body); err != nil || body.Invite == "" {
			http.Error(w, "this server needs an invite to register", http.StatusForbidden)
			return
		}
		invite = inviteHash(body.Invite)
	}
	switch err := a.store.createAccount(r.Context(), account, hash, invite, a.limits.maxAccounts); {
	case errors.Is(err, errAccountExists):
		if !a.answerExisting(w, r, account, hash) {
			internalError(w, errors.New("account vanished during registration"))
		}
	case errors.Is(err, errInvalidInvite):
		http.Error(w, "invalid or expired invite", http.StatusForbidden)
	case errors.Is(err, errRegistrationClosed):
		http.Error(w, "registration closed", http.StatusForbidden)
	case err != nil:
		internalError(w, err)
	default:
		w.WriteHeader(http.StatusCreated)
	}
}

// answerExisting handles registering an account that already exists: a login check that counts as activity.
// It writes nothing and returns false when there is no such account.
func (a *api) answerExisting(w http.ResponseWriter, r *http.Request, account string, hash []byte) bool {
	stored, err := a.store.tokenHash(r.Context(), account)
	switch {
	case err != nil:
		internalError(w, err)
	case stored == nil:
		return false
	case subtle.ConstantTimeCompare(stored, hash) != 1:
		http.Error(w, "bad credentials", http.StatusUnauthorized)
	default:
		if err := a.store.touch(r.Context(), account); err != nil {
			internalError(w, err)
			return true
		}
		w.WriteHeader(http.StatusNoContent)
	}
	return true
}

// clientAddress groups IPv6 clients by /64, the block one machine usually gets.
func (a *api) clientAddress(r *http.Request) (string, error) {
	raw := r.RemoteAddr
	if a.limits.clientIPHeader != "" {
		raw = r.Header.Get(a.limits.clientIPHeader)
	} else if host, _, err := net.SplitHostPort(raw); err == nil {
		raw = host
	}
	addr, err := netip.ParseAddr(raw)
	if err != nil {
		return "", fmt.Errorf("client address %q: %w; the reverse proxy must set %s to the client's IP",
			raw, err, a.limits.clientIPHeader)
	}
	addr = addr.Unmap().WithZone("")
	if addr.Is6() {
		return netip.PrefixFrom(addr, 64).Masked().String(), nil
	}
	return addr.String(), nil
}

// allowRegistration counts an attempt against the client's hourly limit, failed ones included,
// so guessing invites is rate limited too.
func (a *api) allowRegistration(client string, now time.Time) bool {
	a.mu.Lock()
	defer a.mu.Unlock()
	for c, times := range a.registrations {
		recent := times[:0]
		for _, t := range times {
			if now.Sub(t) < time.Hour {
				recent = append(recent, t)
			}
		}
		if len(recent) == 0 {
			delete(a.registrations, c)
		} else {
			a.registrations[c] = recent
		}
	}
	if len(a.registrations[client]) >= a.limits.registerPerHour {
		return false
	}
	a.registrations[client] = append(a.registrations[client], now)
	return true
}

func (a *api) startUpload(account string) bool {
	a.mu.Lock()
	defer a.mu.Unlock()
	if a.uploading[account] {
		return false
	}
	a.uploading[account] = true
	return true
}

func (a *api) endUpload(account string) {
	a.mu.Lock()
	defer a.mu.Unlock()
	delete(a.uploading, account)
}

func (a *api) deleteAccount(w http.ResponseWriter, r *http.Request) {
	if err := a.store.deleteAccount(r.Context(), r.Context().Value(ctxKey{}).(string)); err != nil {
		internalError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (a *api) authed(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		account, hash, ok := credentials(r)
		if !ok {
			http.Error(w, "bad credentials", http.StatusUnauthorized)
			return
		}
		stored, err := a.store.tokenHash(r.Context(), account)
		if err != nil {
			internalError(w, err)
			return
		}
		if stored == nil || subtle.ConstantTimeCompare(stored, hash) != 1 {
			http.Error(w, "bad credentials", http.StatusUnauthorized)
			return
		}
		if err := a.store.touch(r.Context(), account); err != nil {
			internalError(w, err)
			return
		}
		next(w, r.WithContext(context.WithValue(r.Context(), ctxKey{}, account)))
	}
}

func (a *api) named(next func(w http.ResponseWriter, r *http.Request, account, name string)) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		name := r.PathValue("name")
		if !namePattern.MatchString(name) {
			http.Error(w, "bad backup name", http.StatusBadRequest)
			return
		}
		next(w, r, r.Context().Value(ctxKey{}).(string), name)
	}
}

func (a *api) list(w http.ResponseWriter, r *http.Request) {
	backups, err := a.store.list(r.Context(), r.Context().Value(ctxKey{}).(string))
	if err != nil {
		internalError(w, err)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(backups)
}

func (a *api) read(w http.ResponseWriter, r *http.Request, account, name string) {
	data, err := a.store.read(r.Context(), account, name)
	if err != nil {
		internalError(w, err)
		return
	}
	if data == nil {
		http.NotFound(w, r)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.Write(data)
}

func (a *api) write(w http.ResponseWriter, r *http.Request, account, name string) {
	if !a.startUpload(account) {
		http.Error(w, "another upload is running", http.StatusTooManyRequests)
		return
	}
	defer a.endUpload(account)
	select {
	case a.uploads <- struct{}{}:
		defer func() { <-a.uploads }()
	case <-r.Context().Done():
		return
	}
	data, err := io.ReadAll(http.MaxBytesReader(w, r.Body, a.limits.maxBackupBytes))
	if maxErr := (*http.MaxBytesError)(nil); errors.As(err, &maxErr) {
		http.Error(w, "backup too large", http.StatusRequestEntityTooLarge)
		return
	}
	if err != nil {
		http.Error(w, "incomplete upload", http.StatusBadRequest)
		return
	}
	switch err := a.store.write(r.Context(), account, name, data, a.limits.maxBackups); {
	case errors.Is(err, errQuotaExceeded):
		http.Error(w, "too many backups", http.StatusInsufficientStorage)
	case err != nil:
		internalError(w, err)
	default:
		w.WriteHeader(http.StatusNoContent)
	}
}

func (a *api) delete(w http.ResponseWriter, r *http.Request, account, name string) {
	if err := a.store.delete(r.Context(), account, name); err != nil {
		internalError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
