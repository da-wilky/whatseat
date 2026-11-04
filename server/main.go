// Command whatseat-server stores the app's encrypted backups. It never sees a key: accounts and files are opaque to it.
//
// Every flag can also be set as WHATSEAT_<NAME>, e.g. WHATSEAT_INVITE_ONLY=true.
package main

import (
	"context"
	"crypto/rand"
	"encoding/base32"
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
	if len(os.Args) > 1 && os.Args[1] == "invite" {
		invite(os.Args[2:])
		return
	}
	listen := flag.String("listen", "127.0.0.1:8470", "address to listen on; put a TLS reverse proxy in front")
	dbPath := flag.String("db", "whatseat.sqlite", "SQLite database file")
	maxAccounts := flag.Int("max-accounts", 100, "accounts that may exist with open registration; ignored with -invite-only")
	maxBackups := flag.Int("max-backups", 10, "backup files per account; the app keeps 7")
	maxBackupBytes := flag.Int64("max-backup-bytes", 5<<20, "size limit per backup file")
	registerPerHour := flag.Int("register-per-hour", 10, "new accounts per hour, failed attempts included")
	inviteOnly := flag.Bool("invite-only", false, "register only with an invite from 'whatseat-server invite'")
	inactiveDays := flag.Int("inactive-days", 365, "delete accounts and their backups after this many days without a login; 0 keeps them")
	purgeInterval := flag.Duration("purge-interval", 24*time.Hour, "how often inactive accounts and expired invites are deleted; also once at startup")
	envDefaults(flag.CommandLine)
	flag.Parse()
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

func invite(args []string) {
	fs := flag.NewFlagSet("invite", flag.ExitOnError)
	fs.Usage = func() {
		fmt.Fprintln(fs.Output(), "usage: whatseat-server invite [flags] [validity, default 3d, e.g. 30m, 1h, 365d]")
		fs.PrintDefaults()
	}
	dbPath := fs.String("db", "whatseat.sqlite", "SQLite database file")
	publicURL := fs.String("public-url", "", "server address as the app sees it; prints an invite link to paste in the app")
	envDefaults(fs)
	fs.Parse(args)
	if fs.NArg() > 1 {
		fs.Usage()
		os.Exit(2)
	}
	validity := 3 * 24 * time.Hour
	if fs.NArg() == 1 {
		var err error
		if validity, err = parseValidity(fs.Arg(0)); err != nil {
			log.Fatal(err)
		}
	}

	s, err := openStore(*dbPath)
	if err != nil {
		log.Fatal(err)
	}
	defer s.db.Close()
	secret := make([]byte, 15)
	rand.Read(secret)
	code := base32.StdEncoding.EncodeToString(secret)
	expires := time.Now().Add(validity)
	if err := s.createInvite(context.Background(), inviteHash(code), expires); err != nil {
		log.Fatal(err)
	}
	fmt.Printf("Invite (single use, valid until %s): %s\n", expires.Format("2006-01-02 15:04 MST"), code)
	if *publicURL != "" {
		fmt.Printf("Link to paste into the app: %s#invite=%s\n", strings.TrimSuffix(*publicURL, "/")+"/", code)
	}
}
