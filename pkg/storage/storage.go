package storage

import (
	"context"
	"fmt"

	"github.com/unpackdev/downloader/pkg/db"
	"github.com/unpackdev/downloader/pkg/options"
	"github.com/unpackdev/solgo"
)

// Storage struct encapsulates a context, storage options, and a reference to a BadgerDB instance.
// It provides methods to interact with the database, allowing retrieval and storage of entries.
type Storage struct {
	ctx      context.Context
	opts     *options.Storage
	badgerDB *db.BadgerDB
}

// New creates a new Storage instance. It requires a context, storage options, and a BadgerDB instance.
// Returns an error if the provided BadgerDB instance is nil.
func New(ctx context.Context, opts *options.Storage, badgerDB *db.BadgerDB) (*Storage, error) {
	if badgerDB == nil {
		return nil, fmt.Errorf("badgerDB is required")
	}
	return &Storage{ctx, opts, badgerDB}, nil
}

// Get retrieves an Entry from the BadgerDB using its path.
// Returns an error if the entry is nil or if any database operation fails.
func (s *Storage) Get(ctx context.Context, e *Entry) (*Entry, error) {
	if e == nil {
		return nil, fmt.Errorf("entry is required")
	}
	badgerData, err := s.badgerDB.Get(e.GetPath())
	if err != nil {
		return nil, fmt.Errorf("badgerDB get error: %s", err)
	}
	if err := e.UnmarshalBinary(badgerData); err != nil {
		return nil, fmt.Errorf("unmarshal error: %s", err)
	}
	return e, nil
}

// Exists checks if an Entry exists in the BadgerDB.
// Returns an error if the entry is nil.
func (s *Storage) Exists(ctx context.Context, entry *Entry) (bool, error) {
	if entry == nil {
		return false, fmt.Errorf("entry is required")
	}
	return s.badgerDB.Exists(entry.GetPath())
}

// Save writes an Entry and its associated solgo.Sources to the BadgerDB.
// Returns an error if the entry or sources are nil, or if any write operation fails.
func (s *Storage) Save(ctx context.Context, entry *Entry, sources *solgo.Sources) error {
	if entry == nil || sources == nil {
		return fmt.Errorf("entry and sources are required")
	}
	if err := sources.WriteToDir(entry.GetPath()); err != nil {
		return fmt.Errorf("write to dir error: %s", err)
	}
	if err := s.badgerDB.Write(entry.GetPath(), entry.ToBytes()); err != nil {
		return fmt.Errorf("badgerDB write error: %s", err)
	}
	return nil
}
