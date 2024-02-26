package storage

import (
	"context"

	"github.com/ethereum/go-ethereum/common"
	"github.com/unpackdev/solgo"
)

// @TODO: Need to fix the module namespace -> github.com/unpackdev/sourcify-go
func (s *Storage) SeekSourcify(ctx context.Context, addr common.Address) (*solgo.Sources, error) {
	return nil, nil
}
