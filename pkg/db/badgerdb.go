// Package db provides utilities for interacting with BadgerDB v4.
package db

import (
	"context"

	"github.com/dgraph-io/badger/v4"
)

// BadgerDB wraps a Badger DB with additional context and configuration.
type BadgerDB struct {
	ctx    context.Context // Associated context
	dbPath string          // Path where Badger DB is located
	db     *badger.DB      // The Badger DB instance
}

// Option is a function that applies a configuration option to a BadgerDB.
type Option func(*BadgerDB)

// WithDbPath is an Option to set the path of the BadgerDB.
//
// Example usage:
//
//	db, err := NewBadgerDB(WithDbPath("/tmp/mydb"))
func WithDbPath(dbpath string) Option {
	return func(p *BadgerDB) {
		p.dbPath = dbpath
	}
}

// WithContext is an Option to set the context of the BadgerDB.
//
// Example usage:
//
//	ctx := context.Background()
//	db, err := NewBadgerDB(WithContext(ctx))
func WithContext(ctx context.Context) Option {
	return func(p *BadgerDB) {
		p.ctx = ctx
	}
}

// NewBadgerDB creates a new BadgerDB instance with the provided Options.
// It defaults to using a background context if no context is provided.
//
// Example usage:
//
//	ctx := context.Background()
//	db, err := NewBadgerDB(WithContext(ctx), WithDbPath("/tmp/mydb"))
func NewBadgerDB(opts ...Option) (*BadgerDB, error) {
	bdb := &BadgerDB{
		ctx: context.Background(), // Default value
	}

	// Apply the provided options
	for _, opt := range opts {
		opt(bdb)
	}

	bopts := badger.DefaultOptions(bdb.dbPath)

	// Open the Badger database located in the dbPath directory.
	// It will be created if it doesn't exist.
	db, err := badger.Open(bopts)
	if err != nil {
		return nil, err
	}

	bdb.db = db

	return bdb, nil
}

// Get retrieves the value for a given key from the BadgerDB.
//
// Example usage:
//
//	value, err := db.Get("myKey")
func (d *BadgerDB) Get(key string) ([]byte, error) {
	var value []byte

	err := d.db.View(func(txn *badger.Txn) error {
		item, err := txn.Get([]byte(key))
		if err != nil {
			return err
		}
		err = item.Value(func(val []byte) error {
			value = append([]byte{}, val...)
			return nil
		})
		if err != nil {
			return err
		}
		return nil
	})

	if err != nil {
		return nil, err
	}

	return value, nil
}

// Write sets the value for a given key in the BadgerDB.
//
// Example usage:
//
//	err := db.Write("myKey", []byte("myValue"))
func (d *BadgerDB) Write(key string, value []byte) error {
	err := d.db.Update(func(txn *badger.Txn) error {
		err := txn.Set([]byte(key), value)
		return err
	})
	return err
}

// Exists checks if a key exists in the BadgerDB.
//
// Returns a boolean indicating if the key exists and any error encountered.
// It returns true and nil error if the key exists, false and nil error if the key does not exist.
// If an error other than ErrKeyNotFound is encountered during the operation, it returns false and the error.
//
// Example usage:
//
//	exists, err := db.Exists("myKey")
func (d *BadgerDB) Exists(key string) (bool, error) {
	var exists bool
	err := d.db.View(func(txn *badger.Txn) error {
		_, err := txn.Get([]byte(key))
		if err == nil {
			exists = true
		} else if err == badger.ErrKeyNotFound {
			exists = false
		} else {
			return err
		}
		return nil
	})

	return exists, err
}

func (d *BadgerDB) DB() *badger.DB {
	return d.db
}

// Close closes the BadgerDB.
//
// Example usage:
//
//	err := db.Close()
func (d *BadgerDB) Close() error {
	return d.db.Close()
}

// GarbageCollect runs a value log garbage collection on the BadgerDB,
// provided the rewrite ratio is more than 0.7 (70%).
//
// Example usage:
//
//	err := db.GarbageCollect()
func (d *BadgerDB) GarbageCollect() error {
	var err error
	for {
		err = d.db.RunValueLogGC(0.7)
		if err == badger.ErrNoRewrite {
			break
		}
		if err != nil {
			return err
		}
	}
	return nil
}
