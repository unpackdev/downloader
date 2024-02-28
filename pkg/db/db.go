package db

import (
	"context"
	"database/sql"
	"fmt"
	"github.com/unpackdev/inspector/pkg/options"

	_ "modernc.org/sqlite"
)

type Db struct {
	ctx  context.Context
	opts *options.Options
	db   *sql.DB
}

// NewDB ...
// TODO: Add support for multiple dialects... For now only Sqlite3
func NewDB(ctx context.Context, opts *options.Options) (*Db, error) {
	db, err := sql.Open("sqlite", opts.GetSqliteDbPath())
	if err != nil {
		return nil, fmt.Errorf(
			"failure to open database path: %s - err: %w", opts.GetSqliteDbPath(), err,
		)
	}

	toReturn := &Db{
		ctx:  ctx,
		opts: opts,
		db:   db,
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
