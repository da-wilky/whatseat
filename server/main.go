// Command whatseat-server stores the app's encrypted backups. It never sees a key: accounts and files are opaque to it.
//
// Every flag can also be set as WHATSEAT_<NAME>, e.g. WHATSEAT_INVITE_ONLY=true.
package main

import (
	"bufio"
	"context"
	"crypto/rand"
	"encoding/base32"
	"encoding/hex"
	"errors"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"strings"
	"syscall"
	"text/tabwriter"
	"time"
)

// envDefaults makes each flag of fs fall back to its WHATSEAT_* environment variable.
func envDefaults(fs *flag.FlagSet) {
	fs.VisitAll(func(f *flag.Flag) {
		name := "WHATSEAT_" + strings.ToUpper(strings.ReplaceAll(f.Name, "-", "_"))
		if value, ok := os.LookupEnv(name); ok {
			if err := f.Value.Set(value); err != nil {
				log.Fatalf("%s: %v", name, err)
			}
			f.DefValue = value
		}
	})
}

func main() {
	commands := map[string]func([]string){
		"invite":         invite,
		"invites":        listInvites,
		"revoke-invite":  revokeInvite,
		"accounts":       listAccounts,
		"delete-account": deleteAccount,
	}
	if len(os.Args) > 1 {
		if command, ok := commands[os.Args[1]]; ok {
			command(os.Args[2:])
			return
		}
	}
	listen := flag.String("listen", "127.0.0.1:8470", "address to listen on; put a TLS reverse proxy in front")
	dbPath := flag.String("db", "whatseat.sqlite", "SQLite database file")
	maxAccounts := flag.Int("max-accounts", 100, "accounts that may exist with open registration; ignored with -invite-only")
	maxBackups := flag.Int("max-backups", 10, "backup files per account; the app keeps 7")
	maxBackupBytes := flag.Int64("max-backup-bytes", 5<<20, "size limit per backup file")
	registerPerHour := flag.Int("register-per-hour", 10, "new accounts per hour and client address, failed attempts included")
	clientIPHeader := flag.String("client-ip-header", "X-Real-IP", "header the reverse proxy sets to the client's address; empty uses the connection's")
	inviteOnly := flag.Bool("invite-only", false, "register only with an invite from 'whatseat-server invite'")
	inactiveDays := flag.Int("inactive-days", 365, "delete accounts and their backups after this many days without a login; 0 keeps them")
	purgeInterval := flag.Duration("purge-interval", 24*time.Hour, "how often inactive accounts and expired invites are deleted; also once at startup")
	envDefaults(flag.CommandLine)
	flag.Parse()
	if flag.NArg() > 0 {
		log.Fatalf("unknown command %q", flag.Arg(0))
	}
	if *purgeInterval <= 0 {
		log.Fatal("purge-interval must be positive")
	}

	s, err := openStore(*dbPath)
	if err != nil {
		log.Fatal(err)
	}
	defer s.db.Close()

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()
	go purgeLoop(ctx, s, *inactiveDays, *purgeInterval)

	server := &http.Server{
		Addr: *listen,
		Handler: newAPI(s, limits{
			maxAccounts:     *maxAccounts,
			maxBackups:      *maxBackups,
			maxBackupBytes:  *maxBackupBytes,
			inviteOnly:      *inviteOnly,
			inactiveDays:    *inactiveDays,
			registerPerHour: *registerPerHour,
			clientIPHeader:  *clientIPHeader,
		}),
		ReadHeaderTimeout: 10 * time.Second,
		ReadTimeout:       2 * time.Minute,
		WriteTimeout:      2 * time.Minute,
		IdleTimeout:       time.Minute,
	}
	drained := make(chan struct{})
	go func() {
		defer close(drained)
		<-ctx.Done()
		timeout, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		server.Shutdown(timeout)
	}()
	log.Printf("listening on %s", *listen)
	if err := server.ListenAndServe(); !errors.Is(err, http.ErrServerClosed) {
		log.Fatal(err)
	}
	<-drained
}

func purgeLoop(ctx context.Context, s *store, inactiveDays int, interval time.Duration) {
	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	inactive := time.Duration(inactiveDays) * 24 * time.Hour
	for {
		if n, err := s.purge(ctx, time.Now(), inactive, interval); err != nil {
			log.Printf("purge: %v", err)
		} else if n > 0 {
			log.Printf("deleted %d inactive accounts", n)
		}
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
		}
	}
}

// parseValidity accepts Go durations (30m, 1h) plus whole days (3d, 365d).
func parseValidity(s string) (time.Duration, error) {
	var d time.Duration
	var err error
	if days, ok := strings.CutSuffix(s, "d"); ok {
		var n int
		n, err = strconv.Atoi(days)
		d = time.Duration(n) * 24 * time.Hour
	} else {
		d, err = time.ParseDuration(s)
	}
	if err != nil || d <= 0 {
		return 0, fmt.Errorf("invalid validity %q: use e.g. 30m, 1h or 3d", s)
	}
	return d, nil
}

// command is an admin subcommand; it works on the database directly, next to a running server.
// Only flags defined before newCommand returns, or before another envDefaults call, read WHATSEAT_* variables.
type command struct {
	fs      *flag.FlagSet
	dbPath  *string
	maxArgs int
}

func newCommand(name, args string, maxArgs int) *command {
	fs := flag.NewFlagSet(name, flag.ExitOnError)
	fs.Usage = func() {
		fmt.Fprintf(fs.Output(), "usage: whatseat-server %s [flags] %s\n", name, args)
		fs.PrintDefaults()
	}
	dbPath := fs.String("db", "whatseat.sqlite", "SQLite database file")
	envDefaults(fs)
	return &command{fs, dbPath, maxArgs}
}

func (c *command) open(args []string, minArgs int) *store {
	c.fs.Parse(args)
	if c.fs.NArg() < minArgs || c.fs.NArg() > c.maxArgs {
		c.fs.Usage()
		os.Exit(2)
	}
	s, err := openStore(*c.dbPath)
	if err != nil {
		log.Fatal(err)
	}
	return s
}

const timeFormat = "2006-01-02 15:04"

// inviteID shows an invite without its code, which the server doesn't keep.
func inviteID(hash []byte) string {
	return hex.EncodeToString(hash)[:12]
}

// matchPrefix finds the one id starting with prefix, like an abbreviated git commit.
func matchPrefix(prefix string, ids []string) (string, error) {
	if prefix == "" {
		return "", errors.New("empty id")
	}
	prefix = strings.ToLower(prefix)
	var found []string
	for _, id := range ids {
		if strings.HasPrefix(id, prefix) {
			found = append(found, id)
		}
	}
	switch len(found) {
	case 0:
		return "", fmt.Errorf("no match for %q", prefix)
	case 1:
		return found[0], nil
	}
	return "", fmt.Errorf("%q matches %d entries; give more characters", prefix, len(found))
}

func invite(args []string) {
	c := newCommand("invite", "[validity, default 3d, e.g. 30m, 1h, 365d]", 1)
	publicURL := c.fs.String("public-url", "", "server address as the app sees it; prints an invite link to paste in the app")
	envDefaults(c.fs)
	// Defined after envDefaults, like -yes: a stray WHATSEAT_NOTE or WHATSEAT_YES mustn't apply to every call.
	note := c.fs.String("note", "", "who the invite is for; the account it creates keeps it")
	s := c.open(args, 0)
	defer s.db.Close()
	validity := 3 * 24 * time.Hour
	if c.fs.NArg() == 1 {
		var err error
		if validity, err = parseValidity(c.fs.Arg(0)); err != nil {
			log.Fatal(err)
		}
	}

	secret := make([]byte, 15)
	rand.Read(secret)
	code := base32.StdEncoding.EncodeToString(secret)
	expires := time.Now().Add(validity)
	if err := s.createInvite(context.Background(), inviteHash(code), expires, *note); err != nil {
		log.Fatal(err)
	}
	fmt.Printf("Invite %s (single use, valid until %s): %s\n", inviteID(inviteHash(code)), expires.Format("2006-01-02 15:04 MST"), code)
	if *publicURL != "" {
		fmt.Printf("Link to paste into the app: %s#invite=%s\n", strings.TrimSuffix(*publicURL, "/")+"/", code)
	}
}

func listInvites(args []string) {
	s := newCommand("invites", "", 0).open(args, 0)
	defer s.db.Close()
	invites, err := s.invites(context.Background())
	if err != nil {
		log.Fatal(err)
	}
	w := tabwriter.NewWriter(os.Stdout, 0, 0, 2, ' ', 0)
	fmt.Fprintln(w, "ID\tCREATED\tEXPIRES\tNOTE")
	for _, i := range invites {
		created := "-"
		if i.created.UnixMilli() != 0 {
			created = i.created.Format(timeFormat)
		}
		fmt.Fprintf(w, "%s\t%s\t%s\t%s\n", inviteID(i.hash), created, i.expires.Format(timeFormat), i.note)
	}
	w.Flush()
}

func revokeInvite(args []string) {
	c := newCommand("revoke-invite", "ID", 1)
	s := c.open(args, 1)
	defer s.db.Close()
	ctx := context.Background()
	invites, err := s.invites(ctx)
	if err != nil {
		log.Fatal(err)
	}
	ids := make([]string, len(invites))
	for n, i := range invites {
		ids[n] = hex.EncodeToString(i.hash)
	}
	id, err := matchPrefix(c.fs.Arg(0), ids)
	if err != nil {
		log.Fatal(err)
	}
	hash, _ := hex.DecodeString(id)
	if err := s.deleteInvite(ctx, hash); err != nil {
		log.Fatal(err)
	}
	fmt.Printf("Revoked invite %s\n", inviteID(hash))
}

func listAccounts(args []string) {
	s := newCommand("accounts", "", 0).open(args, 0)
	defer s.db.Close()
	accounts, err := s.accounts(context.Background())
	if err != nil {
		log.Fatal(err)
	}
	w := tabwriter.NewWriter(os.Stdout, 0, 0, 2, ' ', 0)
	fmt.Fprintln(w, "ID\tCREATED\tLAST SEEN\tBACKUPS\tSIZE\tNOTE")
	for _, a := range accounts {
		fmt.Fprintf(w, "%s\t%s\t%s\t%d\t%d KiB\t%s\n", a.id, a.created.Format(timeFormat), a.lastSeen.Format(timeFormat),
			a.backups, (a.bytes+1023)/1024, a.note)
	}
	w.Flush()
}

func deleteAccount(args []string) {
	c := newCommand("delete-account", "ID", 1)
	yes := c.fs.Bool("yes", false, "don't ask for confirmation")
	s := c.open(args, 1)
	defer s.db.Close()
	ctx := context.Background()
	accounts, err := s.accounts(ctx)
	if err != nil {
		log.Fatal(err)
	}
	ids := make([]string, len(accounts))
	for n, a := range accounts {
		ids[n] = a.id
	}
	id, err := matchPrefix(c.fs.Arg(0), ids)
	if err != nil {
		log.Fatal(err)
	}
	if !*yes {
		fmt.Printf("Delete account %s and all its backups? Its app recreates it, empty, on the next backup unless registration needs an invite. [y/N] ", id)
		answer, _ := bufio.NewReader(os.Stdin).ReadString('\n')
		if strings.TrimSpace(strings.ToLower(answer)) != "y" {
			fmt.Println("Cancelled")
			return
		}
	}
	if err := s.deleteAccount(ctx, id); err != nil {
		log.Fatal(err)
	}
	fmt.Printf("Deleted account %s\n", id)
}
