package storage

import (
	"context"
	"errors"
	"fmt"
	"math/big"

	"github.com/ethereum/go-ethereum/common"
	"github.com/unpackdev/solgo"
	"github.com/unpackdev/solgo/utils"
	"go.uber.org/zap"
)

var (
	ErrStopIteration = errors.New("stop iteration")
)

// FindContractByAddress searches for contract source code based on network, block number, entry source name, and address.
// It logs the search process and returns the corresponding solgo.Sources if found.
func (s *Storage) FindContractByAddress(ctx context.Context, network utils.Network, block *big.Int, entrySourceName string, addr common.Address) (*solgo.Sources, error) {
	path := s.GetPathByNetworkAndBlockAndAddress(network, block, addr)
	zap.L().Debug(
		"Seeking for contract source code from downloader...",
		zap.Any("network", network),
		zap.Any("block", block),
		zap.String("contract_address", addr.Hex()),
		zap.String("path", path),
	)

	sources, err := solgo.NewSourcesFromPath(entrySourceName, path)
	if err != nil {
		return nil, fmt.Errorf("failure to create new sources from path: %s", err)
	}

	return sources, nil
}

// Seek iterates over all entries in the BadgerDB that match the ENTRY_KEY_PREFIX.
// It accepts a context for operation cancellation and a function to process each Entry.
// The processing function should return a boolean indicating if the iteration should continue.
func (s *Storage) Seek(ctx context.Context, process func(entry *Entry) (bool, error)) error {
	/*	return s.badgerDB.DB().View(func(txn *badger.Txn) error {
		opts := badger.DefaultIteratorOptions
		opts.PrefetchValues = true
		it := txn.NewIterator(opts)
		defer it.Close()

		prefix := []byte(ENTRY_KEY_PREFIX)
		for it.Seek(prefix); it.ValidForPrefix(prefix); it.Next() {
			item := it.Item()
			err := item.Value(func(v []byte) error {
				var entry Entry
				if err := entry.UnmarshalBinary(v); err != nil {
					return fmt.Errorf("failed to unmarshal entry: %w", err)
				}

				// Process the entry using the provided function
				continueIterating, err := process(&entry)
				if err != nil {
					return fmt.Errorf("processing failed: %w", err)
				}

				// If the processing function returns false, stop the iteration
				if !continueIterating {
					return ErrStopIteration
				}
				return nil
			})

			if err != nil {
				if err.Error() == ErrStopIteration.Error() {
					break
				}
				return fmt.Errorf("error iterating entries: %w", err)
			}
		}
		return nil
	})*/
	return nil
}
