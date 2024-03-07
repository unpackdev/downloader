package db

import (
	"context"
	"database/sql"
	"fmt"
	"github.com/doug-martin/goqu/v9"
	"github.com/unpackdev/inspector/pkg/options"

	_ "modernc.org/sqlite"
)

type Db struct {
	ctx    context.Context
	opts   *options.Options
	db     *sql.DB
	goquDb *goqu.Database
}

// NewDB ...
// TODO: Add support for multiple dialects... For now only Sqlite3
func NewDB(ctx context.Context, opts *options.Options) (*Db, error) {
	dbPath := opts.GetSqliteDbPath() + "?cache=shared"
	db, err := sql.Open("sqlite", dbPath)
	if err != nil {
		return nil, fmt.Errorf(
			"failure to open database path: %s - err: %w", opts.GetSqliteDbPath(), err,
		)
	}

	// DEFAULT - HAND-CODED CONFIGURATION ------------------------------------
	// WARN: DO NOT MODIFY!!
	// There can be only one connection to the sqlite database.
	// WAL mode must be present, so we can read regardless of the writing.
	// Otherwise, if not present you will start getting `database is locked (5) (SQLITE_BUSY)`
	// Do not alter, do not modify and just leave it alone unless you wish to see the error yourself.
	db.SetMaxOpenConns(1)

	if _, err = db.Exec(`PRAGMA journal_mode=WAL;`); err != nil {
		return nil, fmt.Errorf(
			"failed to set database to WAL mode: %w", err,
		)
	}
	// -----------------------------------------------------------------------

	toReturn := &Db{
		ctx:    ctx,
		opts:   opts,
		db:     db,
		goquDb: goqu.New("sqlite3", db),
	}

	return toReturn, nil
}

func (d *Db) GetDatasource() string {
	return d.opts.Db.Datasource
}

func (d *Db) GetDialect() string {
	return d.opts.Db.Dialect
}

func (d *Db) GetDB() *sql.DB {
	return d.db
}

func (d *Db) GetGoqu() *goqu.Database { return d.goquDb }
