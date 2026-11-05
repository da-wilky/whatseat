package main

import (
	"bytes"
	"context"
	"encoding/base64"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

const (
	account = "0123456789abcdef0123456789abcdef"
	backup  = "/v1/backups/whatseat-backup-2026-11-04.json"
)

var token = base64.RawURLEncoding.EncodeToString(bytes.Repeat([]byte{7}, 32))

func newTestServer(t *testing.T, l limits) *httptest.Server {
	t.Helper()
	s, err := openStore(filepath.Join(t.TempDir(), "test.sqlite"))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { s.db.Close() })
	server := httptest.NewServer(newAPI(s, l))
	t.Cleanup(server.Close)
	return server
}

func do(t *testing.T, server *httptest.Server, method, path, auth string, body string) (int, string) {
	t.Helper()
	req, err := http.NewRequest(method, server.URL+path, strings.NewReader(body))
	if err != nil {
		t.Fatal(err)
	}
	if auth != "" {
		req.Header.Set("Authorization", "Bearer "+auth)
	}
	res, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatal(err)
	}
	defer res.Body.Close()
	data, _ := io.ReadAll(res.Body)
	return res.StatusCode, string(data)
}

func expect(t *testing.T, got, want int, what string) {
	t.Helper()
	if got != want {
		t.Fatalf("%s: status %d, want %d", what, got, want)
	}
}

var defaultLimits = limits{registerPerHour: 100, maxAccounts: 10, maxBackups: 2, maxBackupBytes: 1 << 10}

func TestBackupLifecycle(t *testing.T) {
	server := newTestServer(t, defaultLimits)
	auth := account + "." + token

	status, _ := do(t, server, "GET", "/v1/backups", auth, "")
	expect(t, status, http.StatusUnauthorized, "list before register")
	status, _ = do(t, server, "POST", "/v1/register", auth, "")
	expect(t, status, http.StatusCreated, "register")
	status, _ = do(t, server, "POST", "/v1/register", auth, "")
	expect(t, status, http.StatusNoContent, "register again")

	status, _ = do(t, server, "PUT", backup, auth, `{"format":"whatseat-backup-encrypted"}`)
	expect(t, status, http.StatusNoContent, "upload")
	status, body := do(t, server, "GET", backup, auth, "")
	expect(t, status, http.StatusOK, "download")
	if body != `{"format":"whatseat-backup-encrypted"}` {
		t.Fatalf("download returned %q", body)
	}

	status, body = do(t, server, "GET", "/v1/backups", auth, "")
	expect(t, status, http.StatusOK, "list")
	var listed []backupInfo
	if err := json.Unmarshal([]byte(body), &listed); err != nil || len(listed) != 1 || listed[0].Name != "whatseat-backup-2026-11-04.json" {
		t.Fatalf("list returned %s (%v)", body, err)
	}

	status, _ = do(t, server, "DELETE", backup, auth, "")
	expect(t, status, http.StatusNoContent, "delete")
	status, _ = do(t, server, "GET", backup, auth, "")
	expect(t, status, http.StatusNotFound, "download deleted")
}

func TestRejectsOtherCredentials(t *testing.T) {
	server := newTestServer(t, defaultLimits)
	do(t, server, "POST", "/v1/register", account+"."+token, "")
	other := base64.RawURLEncoding.EncodeToString(bytes.Repeat([]byte{8}, 32))

	for what, auth := range map[string]string{
		"wrong token":     account + "." + other,
		"short token":     account + ".abc",
		"bad account":     "ACCOUNT." + token,
		"no credentials":  "",
		"missing account": "." + token,
	} {
		status, _ := do(t, server, "GET", "/v1/backups", auth, "")
		expect(t, status, http.StatusUnauthorized, what)
	}
	status, _ := do(t, server, "POST", "/v1/register", account+"."+other, "")
	expect(t, status, http.StatusUnauthorized, "register taken account")
}

func TestLimits(t *testing.T) {
	server := newTestServer(t, limits{registerPerHour: 100, maxAccounts: 1, maxBackups: 2, maxBackupBytes: 16})
	auth := account + "." + token
	do(t, server, "POST", "/v1/register", auth, "")

	status, _ := do(t, server, "POST", "/v1/register", "fedcba9876543210fedcba9876543210."+token, "")
	expect(t, status, http.StatusForbidden, "register beyond max accounts")
	status, _ = do(t, server, "PUT", "/v1/backups/notes.txt", auth, "{}")
	expect(t, status, http.StatusBadRequest, "foreign file name")
	status, _ = do(t, server, "PUT", backup, auth, strings.Repeat("x", 17))
	expect(t, status, http.StatusRequestEntityTooLarge, "oversized upload")

	do(t, server, "PUT", "/v1/backups/whatseat-backup-2026-11-01.json", auth, "{}")
	do(t, server, "PUT", "/v1/backups/whatseat-backup-2026-11-02.json", auth, "{}")
	status, _ = do(t, server, "PUT", backup, auth, "{}")
	expect(t, status, http.StatusInsufficientStorage, "beyond max backups")
	status, _ = do(t, server, "PUT", "/v1/backups/whatseat-backup-2026-11-02.json", auth, "{}")
	expect(t, status, http.StatusNoContent, "replace existing at quota")
}

func TestInviteOnly(t *testing.T) {
	s, err := openStore(filepath.Join(t.TempDir(), "test.sqlite"))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { s.db.Close() })
	server := httptest.NewServer(newAPI(s, limits{registerPerHour: 100, maxAccounts: 10, maxBackups: 2, maxBackupBytes: 16, inviteOnly: true, inactiveDays: 30}))
	t.Cleanup(server.Close)
	auth := account + "." + token

	status, body := do(t, server, "GET", "/v1/info", "", "")
	expect(t, status, http.StatusOK, "info")
	if strings.TrimSpace(body) != `{"inactiveDays":30,"inviteOnly":true}` {
		t.Fatalf("info returned %s", body)
	}

	status, _ = do(t, server, "POST", "/v1/register", auth, "")
	expect(t, status, http.StatusForbidden, "register without invite")
	status, _ = do(t, server, "POST", "/v1/register", auth, `{"invite":"NOPE"}`)
	expect(t, status, http.StatusForbidden, "register with unknown invite")

	ctx := context.Background()
	if err := s.createInvite(ctx, inviteHash("ABCD2345"), time.Now().Add(time.Hour)); err != nil {
		t.Fatal(err)
	}
	if err := s.createInvite(ctx, inviteHash("EXPIRED2"), time.Now().Add(-time.Hour)); err != nil {
		t.Fatal(err)
	}
	status, _ = do(t, server, "POST", "/v1/register", auth, `{"invite":"expired2"}`)
	expect(t, status, http.StatusForbidden, "register with expired invite")
	status, _ = do(t, server, "POST", "/v1/invite/check", "", `{"invite":"NOPE"}`)
	expect(t, status, http.StatusForbidden, "check unknown invite")
	status, _ = do(t, server, "POST", "/v1/invite/check", "", `{"invite":"expired2"}`)
	expect(t, status, http.StatusForbidden, "check expired invite")
	status, _ = do(t, server, "POST", "/v1/invite/check", "", "")
	expect(t, status, http.StatusBadRequest, "check without invite")
	status, _ = do(t, server, "POST", "/v1/invite/check", "", `{"invite":"abcd-2345"}`)
	expect(t, status, http.StatusNoContent, "check valid invite")
	status, _ = do(t, server, "POST", "/v1/invite/check", "", `{"invite":"abcd-2345"}`)
	expect(t, status, http.StatusNoContent, "check doesn't use up the invite")
	status, _ = do(t, server, "POST", "/v1/register", auth, `{"invite":"abcd-2345"}`)
	expect(t, status, http.StatusCreated, "register with invite as typed")
	status, _ = do(t, server, "POST", "/v1/register", auth, "")
	expect(t, status, http.StatusNoContent, "existing account needs no invite")

	status, _ = do(t, server, "POST", "/v1/register", "fedcba9876543210fedcba9876543210."+token, `{"invite":"ABCD2345"}`)
	expect(t, status, http.StatusForbidden, "invite is single use")
}

func TestParseValidity(t *testing.T) {
	for in, want := range map[string]time.Duration{"30m": 30 * time.Minute, "1h": time.Hour, "3d": 72 * time.Hour, "365d": 365 * 24 * time.Hour} {
		if got, err := parseValidity(in); err != nil || got != want {
			t.Errorf("parseValidity(%q) = %v, %v", in, got, err)
		}
	}
	for _, in := range []string{"", "0d", "-1h", "3w", "d"} {
		if _, err := parseValidity(in); err == nil {
			t.Errorf("parseValidity(%q) accepted", in)
		}
	}
}

func TestInviteOnlyIgnoresMaxAccounts(t *testing.T) {
	s, err := openStore(filepath.Join(t.TempDir(), "test.sqlite"))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { s.db.Close() })
	server := httptest.NewServer(newAPI(s, limits{registerPerHour: 100, maxAccounts: 0, maxBackups: 1, maxBackupBytes: 16, inviteOnly: true}))
	t.Cleanup(server.Close)
	if err := s.createInvite(context.Background(), inviteHash("ABCD2345"), time.Now().Add(time.Hour)); err != nil {
		t.Fatal(err)
	}
	status, _ := do(t, server, "POST", "/v1/register", account+"."+token, `{"invite":"ABCD2345"}`)
	expect(t, status, http.StatusCreated, "register with invite despite maxAccounts 0")
}

func TestPurgesInactiveAccounts(t *testing.T) {
	s, err := openStore(filepath.Join(t.TempDir(), "test.sqlite"))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { s.db.Close() })
	server := httptest.NewServer(newAPI(s, defaultLimits))
	t.Cleanup(server.Close)
	auth := account + "." + token
	do(t, server, "POST", "/v1/register", auth, "")
	do(t, server, "PUT", backup, auth, "{}")

	ctx := context.Background()
	now := time.Now()
	const day = 24 * time.Hour
	purge := func(at time.Time, inactive time.Duration) int64 {
		t.Helper()
		n, err := s.purge(ctx, at, inactive, day)
		if err != nil {
			t.Fatal(err)
		}
		return n
	}
	purge(now, 30*day)

	if _, err := s.db.Exec(`UPDATE accounts SET last_seen = ?`, now.Add(-40*day).UnixMilli()); err != nil {
		t.Fatal(err)
	}
	status, _ := do(t, server, "POST", "/v1/ping", auth, "")
	expect(t, status, http.StatusOK, "ping")
	if n := purge(now.Add(day), 30*day); n != 0 {
		t.Fatalf("purge after ping deleted %d", n)
	}

	if _, err := s.db.Exec(`UPDATE accounts SET last_seen = ?`, now.Add(-20*day).UnixMilli()); err != nil {
		t.Fatal(err)
	}
	// The server was down for 60 days: that must not count against the account.
	if n := purge(now.Add(61*day), 30*day); n != 0 {
		t.Fatalf("purge after downtime deleted %d", n)
	}
	if n := purge(now.Add(62*day), 0); n != 0 {
		t.Fatalf("purge without limit deleted %d", n)
	}
	if n := purge(now.Add(63*day), 30*day); n != 0 {
		t.Fatalf("purge within the credited time deleted %d", n)
	}
	// Running daily, the credited account (last seen 20 days before the 60-day outage) expires on day 70.
	var deleted int64
	for d := 64; d <= 70; d++ {
		deleted += purge(now.Add(time.Duration(d)*day), 30*day)
	}
	if deleted != 1 {
		t.Fatalf("purge deleted %d", deleted)
	}
	var left int
	s.db.QueryRow(`SELECT COUNT(*) FROM backups`).Scan(&left)
	if left != 0 {
		t.Fatalf("%d backups left after their account was deleted", left)
	}
	status, _ = do(t, server, "GET", "/v1/backups", auth, "")
	expect(t, status, http.StatusUnauthorized, "deleted account")
}

func TestDeleteAccount(t *testing.T) {
	server := newTestServer(t, defaultLimits)
	auth := account + "." + token
	do(t, server, "POST", "/v1/register", auth, "")
	do(t, server, "PUT", "/v1/backups/whatseat-backup-2026-11-04-0a1b2c3d.json", auth, "{}")
	status, _ := do(t, server, "DELETE", "/v1/account", auth, "")
	expect(t, status, http.StatusNoContent, "delete account")
	status, _ = do(t, server, "GET", "/v1/backups", auth, "")
	expect(t, status, http.StatusUnauthorized, "list after delete")
}

func TestRegistrationRateLimit(t *testing.T) {
	server := newTestServer(t, limits{registerPerHour: 2, maxAccounts: 10, maxBackups: 1, maxBackupBytes: 16})
	for i, want := range []int{http.StatusCreated, http.StatusCreated, http.StatusTooManyRequests} {
		id := strings.Repeat(string("abc"[i]), 32)
		status, _ := do(t, server, "POST", "/v1/register", id+"."+token, "")
		expect(t, status, want, "registration "+id)
	}
	status, _ := do(t, server, "POST", "/v1/register", strings.Repeat("a", 32)+"."+token, "")
	expect(t, status, http.StatusNoContent, "existing account logs in despite the limit")
}

func TestRegistrationRateLimitPerClient(t *testing.T) {
	server := newTestServer(t, limits{registerPerHour: 1, maxAccounts: 10, maxBackups: 1, maxBackupBytes: 16, clientIPHeader: "X-Real-IP"})
	register := func(id, client string) int {
		t.Helper()
		req, err := http.NewRequest("POST", server.URL+"/v1/register", nil)
		if err != nil {
			t.Fatal(err)
		}
		req.Header.Set("Authorization", "Bearer "+strings.Repeat(id, 32)+"."+token)
		if client != "" {
			req.Header.Set("X-Real-IP", client)
		}
		res, err := http.DefaultClient.Do(req)
		if err != nil {
			t.Fatal(err)
		}
		res.Body.Close()
		return res.StatusCode
	}
	expect(t, register("a", "192.0.2.1"), http.StatusCreated, "first client")
	expect(t, register("b", "192.0.2.1"), http.StatusTooManyRequests, "first client again")
	expect(t, register("c", "192.0.2.2"), http.StatusCreated, "second client")
	expect(t, register("d", "2001:db8::1"), http.StatusCreated, "IPv6 client")
	expect(t, register("e", "2001:db8::2"), http.StatusTooManyRequests, "same IPv6 /64")
	expect(t, register("f", ""), http.StatusInternalServerError, "proxy didn't set the header")
}

func TestOneUploadPerAccount(t *testing.T) {
	server := newTestServer(t, defaultLimits)
	auth := account + "." + token
	do(t, server, "POST", "/v1/register", auth, "")

	body, slow := io.Pipe()
	req, err := http.NewRequest("PUT", server.URL+backup, body)
	if err != nil {
		t.Fatal(err)
	}
	req.Header.Set("Authorization", "Bearer "+auth)
	done := make(chan int)
	go func() {
		res, err := http.DefaultClient.Do(req)
		if err != nil {
			done <- 0
			return
		}
		res.Body.Close()
		done <- res.StatusCode
	}()
	slow.Write([]byte("{"))
	// The first upload never finishes on its own, so it takes the account's slot sooner or later.
	for deadline := time.Now().Add(5 * time.Second); ; {
		status, _ := do(t, server, "PUT", "/v1/backups/whatseat-backup-2026-11-01.json", auth, "{}")
		if status == http.StatusTooManyRequests {
			break
		}
		if time.Now().After(deadline) {
			t.Fatalf("second upload while one runs: status %d", status)
		}
	}
	slow.Write([]byte("}"))
	slow.Close()
	expect(t, <-done, http.StatusNoContent, "first upload")
	status, _ := do(t, server, "PUT", "/v1/backups/whatseat-backup-2026-11-01.json", auth, "{}")
	expect(t, status, http.StatusNoContent, "upload after the first finished")
}

func TestPurgeAfterClockWentBack(t *testing.T) {
	s, err := openStore(filepath.Join(t.TempDir(), "test.sqlite"))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { s.db.Close() })
	ctx := context.Background()
	if err := s.createAccount(ctx, account, inviteHash("token"), nil, 1); err != nil {
		t.Fatal(err)
	}
	const day = 24 * time.Hour
	now := time.Now()
	if _, err := s.purge(ctx, now.Add(400*day), 0, day); err != nil {
		t.Fatal(err)
	}
	// Corrected from a clock 400 days ahead: nothing is deleted, and the reckoning restarts from the real time.
	if _, err := s.purge(ctx, now, 30*day, day); !errors.Is(err, errClockBackwards) {
		t.Fatalf("purge with the clock behind: %v", err)
	}
	if n, err := s.purge(ctx, now.Add(day), 30*day, day); err != nil || n != 0 {
		t.Fatalf("purge after the reset deleted %d (%v)", n, err)
	}
	if n, err := s.purge(ctx, now.Add(32*day), 30*day, 31*day); err != nil || n != 1 {
		t.Fatalf("purge once really inactive deleted %d (%v)", n, err)
	}
}

func TestRegisteringTwiceKeepsTheInvite(t *testing.T) {
	s, err := openStore(filepath.Join(t.TempDir(), "test.sqlite"))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { s.db.Close() })
	ctx := context.Background()
	s.createInvite(ctx, inviteHash("FIRST234"), time.Now().Add(time.Hour))
	s.createInvite(ctx, inviteHash("SECOND23"), time.Now().Add(time.Hour))
	hash := inviteHash("token")
	if err := s.createAccount(ctx, account, hash, inviteHash("FIRST234"), 0); err != nil {
		t.Fatal(err)
	}
	if err := s.createAccount(ctx, account, hash, inviteHash("SECOND23"), 0); !errors.Is(err, errAccountExists) {
		t.Fatalf("second registration: %v", err)
	}
	if err := s.createAccount(ctx, "fedcba9876543210fedcba9876543210", hash, inviteHash("SECOND23"), 0); err != nil {
		t.Fatalf("invite was used up by the failed registration: %v", err)
	}
}
