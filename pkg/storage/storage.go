package storage

import (
	"context"
	"fmt"
	"path/filepath"

	"github.com/unpackdev/inspector/pkg/db"
	"github.com/unpackdev/inspector/pkg/options"
	"github.com/unpackdev/solgo"
)

// Storage struct encapsulates a context, storage options, and a reference to a BadgerDB instance.
// It provides methods to interact with the database, allowing retrieval and storage of entries.
type Storage struct {
	ctx  context.Context
	opts options.Storage
	db   *db.Db
}

// New creates a new Storage instance. It requires a context, storage options, and a BadgerDB instance.
// Returns an error if the provided BadgerDB instance is nil.
func New(ctx context.Context, opts options.Storage, db *db.Db) (*Storage, error) {
	if db == nil {
		return nil, fmt.Errorf("database instance is required")
	}
	return &Storage{ctx, opts, db}, nil
}

// Get retrieves an Entry from the BadgerDB using its path.
// Returns an error if the entry is nil or if any database operation fails.
func (s *Storage) Get(ctx context.Context, e *Entry) (*Entry, error) {
	if e == nil {
		return nil, fmt.Errorf("entry is required")
	}
	/*	badgerData, err := s.badgerDB.Get(e.GetKey())
		if err != nil {
			return nil, fmt.Errorf("badgerDB get error: %s", err)
		}
		if err := e.UnmarshalBinary(badgerData); err != nil {
			return nil, fmt.Errorf("unmarshal error: %s", err)
		}
		return e, nil*/

	return nil, nil
}

// Exists checks if an Entry exists in the BadgerDB.
// Returns an error if the entry is nil.
func (s *Storage) Exists(ctx context.Context, entry *Entry) (bool, error) {
	/*	if entry == nil {
			return false, fmt.Errorf("entry is required")
		}
		return s.badgerDB.Exists(entry.GetKey())*/
	return false, nil
}

// Save writes an Entry and its associated solgo.Sources to the BadgerDB.
// Returns an error if the entry or sources are nil, or if any write operation fails.
func (s *Storage) Save(ctx context.Context, entry *Entry, sources *solgo.Sources) error {
	/*	if entry == nil || sources == nil {
			return fmt.Errorf("entry and sources are required")
		}

		if err := sources.WriteToDir(s.GetEntryFullPath(entry)); err != nil {
			return fmt.Errorf("write to dir error: %s", err)
		}
		if err := s.badgerDB.Write(ctx, entry.GetKey(), entry.ToBytes()); err != nil {
			return fmt.Errorf("badgerDB write error: %s", err)
		}*/
	return nil
}

func (s *Storage) GetEntryFullPath(entry *Entry) string {
	return filepath.Join(
		s.opts.ContractsPath,
		entry.GetPath(),
	)
}
