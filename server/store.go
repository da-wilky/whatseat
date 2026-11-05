package main

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"time"

	_ "modernc.org/sqlite"
)

var (
	errClockBackwards     = errors.New("clock is behind the last purge; skipping it until it catches up")
	errRegistrationClosed = errors.New("registration closed")
	errInvalidInvite      = errors.New("invalid or expired invite")
	errAccountExists      = errors.New("account exists")
	errQuotaExceeded      = errors.New("too many backups")
)

// Kept to SQL that SQLite and PostgreSQL both accept, apart from placeholders.
var migrations = []string{
	`CREATE TABLE accounts (
		id TEXT PRIMARY KEY,
		token_hash BLOB NOT NULL,
		created_at BIGINT NOT NULL
	)`,
	`CREATE TABLE backups (
		account_id TEXT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
		name TEXT NOT NULL,
		data BLOB NOT NULL,
		modified_at BIGINT NOT NULL,
		PRIMARY KEY (account_id, name)
	)`,
	`ALTER TABLE accounts ADD COLUMN last_seen BIGINT NOT NULL DEFAULT 0`,
	`UPDATE accounts SET last_seen = created_at`,
	`CREATE TABLE invites (
		code_hash BLOB PRIMARY KEY,
		expires_at BIGINT NOT NULL
	)`,
	`CREATE TABLE heartbeat (last_alive BIGINT NOT NULL)`,
	`ALTER TABLE invites ADD COLUMN created_at BIGINT NOT NULL DEFAULT 0`,
	`ALTER TABLE invites ADD COLUMN note TEXT NOT NULL DEFAULT ''`,
	`ALTER TABLE accounts ADD COLUMN note TEXT NOT NULL DEFAULT ''`,
}

type store struct{ db *sql.DB }

type backupInfo struct {
	Name     string    `json:"name"`
	Size     int       `json:"size"`
	Modified time.Time `json:"modified"`
}

type inviteInfo struct {
	hash             []byte
	note             string
	created, expires time.Time
}

type accountInfo struct {
	id                string
	note              string
	created, lastSeen time.Time
	backups           int
	bytes             int64
}

func openStore(path string) (*store, error) {
	db, err := sql.Open("sqlite", "file:"+path+"?_pragma=foreign_keys(1)&_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)")
	if err != nil {
		return nil, err
	}
	// One connection serialises writers, so the quota checks can't race.
	db.SetMaxOpenConns(1)
	s := &store{db}
	if err := s.migrate(); err != nil {
		db.Close()
		return nil, err
	}
	return s, nil
}

func (s *store) migrate() error {
	tx, err := s.db.Begin()
	if err != nil {
		return err
	}
	defer tx.Rollback()
	if _, err := tx.Exec(`CREATE TABLE IF NOT EXISTS schema_version (version INTEGER NOT NULL)`); err != nil {
		return err
	}
	var version int
	if err := tx.QueryRow(`SELECT COALESCE(MAX(version), 0) FROM schema_version`).Scan(&version); err != nil {
		return err
	}
	if version > len(migrations) {
		return fmt.Errorf("database schema %d is newer than this server (%d)", version, len(migrations))
	}
	for i, m := range migrations[version:] {
		if _, err := tx.Exec(m); err != nil {
			return fmt.Errorf("migration %d: %w", version+i+1, err)
		}
	}
	if _, err := tx.Exec(`DELETE FROM schema_version`); err != nil {
		return err
	}
	if _, err := tx.Exec(`INSERT INTO schema_version (version) VALUES (?)`, len(migrations)); err != nil {
		return err
	}
	return tx.Commit()
}

// tokenHash is nil for an unknown account.
func (s *store) tokenHash(ctx context.Context, account string) ([]byte, error) {
	var hash []byte
	err := s.db.QueryRowContext(ctx, `SELECT token_hash FROM accounts WHERE id = ?`, account).Scan(&hash)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	return hash, err
}

// createAccount uses up the invite and takes over its note; a nil inviteHash means registration is open, limited by maxAccounts.
func (s *store) createAccount(ctx context.Context, account string, tokenHash, inviteHash []byte, maxAccounts int) error {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()
	now := time.Now().UnixMilli()
	note := ""
	if inviteHash != nil {
		err := tx.QueryRowContext(ctx, `DELETE FROM invites WHERE code_hash = ? AND expires_at > ? RETURNING note`,
			inviteHash, now).Scan(&note)
		if errors.Is(err, sql.ErrNoRows) {
			return errInvalidInvite
		}
		if err != nil {
			return err
		}
	} else {
		var count int
		if err := tx.QueryRowContext(ctx, `SELECT COUNT(*) FROM accounts`).Scan(&count); err != nil {
			return err
		}
		if count >= maxAccounts {
			return errRegistrationClosed
		}
	}
	// A concurrent registration may have created it since the caller looked; the invite then stays unused.
	res, err := tx.ExecContext(ctx, `INSERT INTO accounts (id, token_hash, created_at, last_seen, note) VALUES (?, ?, ?, ?, ?)
		ON CONFLICT (id) DO NOTHING`, account, tokenHash, now, now, note)
	if err != nil {
		return err
	}
	if n, err := res.RowsAffected(); err != nil || n == 0 {
		return errors.Join(errAccountExists, err)
	}
	return tx.Commit()
}

func (s *store) touch(ctx context.Context, account string) error {
	_, err := s.db.ExecContext(ctx, `UPDATE accounts SET last_seen = ? WHERE id = ?`, time.Now().UnixMilli(), account)
	return err
}

func (s *store) createInvite(ctx context.Context, codeHash []byte, expires time.Time, note string) error {
	_, err := s.db.ExecContext(ctx, `INSERT INTO invites (code_hash, expires_at, created_at, note) VALUES (?, ?, ?, ?)`,
		codeHash, expires.UnixMilli(), time.Now().UnixMilli(), note)
	return err
}

// invites lists the usable ones; expired invites wait for the next purge.
func (s *store) invites(ctx context.Context) ([]inviteInfo, error) {
	rows, err := s.db.QueryContext(ctx, `SELECT code_hash, note, created_at, expires_at FROM invites
		WHERE expires_at > ? ORDER BY created_at`, time.Now().UnixMilli())
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var invites []inviteInfo
	for rows.Next() {
		var i inviteInfo
		var created, expires int64
		if err := rows.Scan(&i.hash, &i.note, &created, &expires); err != nil {
			return nil, err
		}
		i.created, i.expires = time.UnixMilli(created), time.UnixMilli(expires)
		invites = append(invites, i)
	}
	return invites, rows.Err()
}

func (s *store) deleteInvite(ctx context.Context, codeHash []byte) error {
	_, err := s.db.ExecContext(ctx, `DELETE FROM invites WHERE code_hash = ?`, codeHash)
	return err
}

func (s *store) accounts(ctx context.Context) ([]accountInfo, error) {
	rows, err := s.db.QueryContext(ctx, `SELECT a.id, a.note, a.created_at, a.last_seen,
			COUNT(b.name), COALESCE(SUM(LENGTH(b.data)), 0)
		FROM accounts a LEFT JOIN backups b ON b.account_id = a.id
		GROUP BY a.id, a.note, a.created_at, a.last_seen ORDER BY a.created_at`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var accounts []accountInfo
	for rows.Next() {
		var a accountInfo
		var created, lastSeen int64
		if err := rows.Scan(&a.id, &a.note, &created, &lastSeen, &a.backups, &a.bytes); err != nil {
			return nil, err
		}
		a.created, a.lastSeen = time.UnixMilli(created), time.UnixMilli(lastSeen)
		accounts = append(accounts, a)
	}
	return accounts, rows.Err()
}

func (s *store) inviteValid(ctx context.Context, codeHash []byte) (bool, error) {
	var valid bool
	err := s.db.QueryRowContext(ctx, `SELECT EXISTS (SELECT 1 FROM invites WHERE code_hash = ? AND expires_at > ?)`,
		codeHash, time.Now().UnixMilli()).Scan(&valid)
	return valid, err
}

// purge deletes accounts unseen for longer than inactive, with their backups, and expired invites.
// A zero inactive keeps all accounts. It runs every interval; a longer gap since the last run means the server
// was down or the clock jumped, and that time is credited to every account instead of counting as inactivity.
func (s *store) purge(ctx context.Context, now time.Time, inactive, interval time.Duration) (accounts int64, err error) {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return 0, err
	}
	defer tx.Rollback()
	var lastAlive int64
	switch err := tx.QueryRowContext(ctx, `SELECT last_alive FROM heartbeat`).Scan(&lastAlive); {
	case errors.Is(err, sql.ErrNoRows):
		lastAlive = now.UnixMilli()
	case err != nil:
		return 0, err
	}
	gap := time.Duration(now.UnixMilli()-lastAlive) * time.Millisecond
	if gap < 0 {
		// Restart the reckoning from here; deleting nothing this round is the safe side either way.
		if err := setHeartbeat(ctx, tx, now); err != nil {
			return 0, err
		}
		return 0, errors.Join(errClockBackwards, tx.Commit())
	}
	if gap > 2*interval {
		if _, err := tx.ExecContext(ctx, `UPDATE accounts SET last_seen = last_seen + ?`, (gap - interval).Milliseconds()); err != nil {
			return 0, err
		}
	}
	if inactive > 0 {
		res, err := tx.ExecContext(ctx, `DELETE FROM accounts WHERE last_seen < ?`, now.Add(-inactive).UnixMilli())
		if err != nil {
			return 0, err
		}
		if accounts, err = res.RowsAffected(); err != nil {
			return 0, err
		}
	}
	if _, err := tx.ExecContext(ctx, `DELETE FROM invites WHERE expires_at <= ?`, now.UnixMilli()); err != nil {
		return 0, err
	}
	if err := setHeartbeat(ctx, tx, now); err != nil {
		return 0, err
	}
	return accounts, tx.Commit()
}

func setHeartbeat(ctx context.Context, tx *sql.Tx, now time.Time) error {
	if _, err := tx.ExecContext(ctx, `DELETE FROM heartbeat`); err != nil {
		return err
	}
	_, err := tx.ExecContext(ctx, `INSERT INTO heartbeat (last_alive) VALUES (?)`, now.UnixMilli())
	return err
}

func (s *store) deleteAccount(ctx context.Context, account string) error {
	_, err := s.db.ExecContext(ctx, `DELETE FROM accounts WHERE id = ?`, account)
	return err
}

func (s *store) list(ctx context.Context, account string) ([]backupInfo, error) {
	rows, err := s.db.QueryContext(ctx,
		`SELECT name, LENGTH(data), modified_at FROM backups WHERE account_id = ? ORDER BY name DESC`, account)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	backups := []backupInfo{}
	for rows.Next() {
		var b backupInfo
		var modified int64
		if err := rows.Scan(&b.Name, &b.Size, &modified); err != nil {
			return nil, err
		}
		b.Modified = time.UnixMilli(modified).UTC()
		backups = append(backups, b)
	}
	return backups, rows.Err()
}

// read returns nil for a missing backup.
func (s *store) read(ctx context.Context, account, name string) ([]byte, error) {
	var data []byte
	err := s.db.QueryRowContext(ctx, `SELECT data FROM backups WHERE account_id = ? AND name = ?`, account, name).Scan(&data)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	return data, err
}

func (s *store) write(ctx context.Context, account, name string, data []byte, maxBackups int) error {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()
	var others int
	if err := tx.QueryRowContext(ctx, `SELECT COUNT(*) FROM backups WHERE account_id = ? AND name <> ?`,
		account, name).Scan(&others); err != nil {
		return err
	}
	if others >= maxBackups {
		return errQuotaExceeded
	}
	if _, err := tx.ExecContext(ctx, `INSERT INTO backups (account_id, name, data, modified_at) VALUES (?, ?, ?, ?)
		ON CONFLICT (account_id, name) DO UPDATE SET data = excluded.data, modified_at = excluded.modified_at`,
		account, name, data, time.Now().UnixMilli()); err != nil {
		return err
	}
	return tx.Commit()
}

func (s *store) delete(ctx context.Context, account, name string) error {
	_, err := s.db.ExecContext(ctx, `DELETE FROM backups WHERE account_id = ? AND name = ?`, account, name)
	return err
}
