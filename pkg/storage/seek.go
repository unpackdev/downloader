package storage

import (
	"context"
	"fmt"
	"math/big"

	"github.com/ethereum/go-ethereum/common"
	"github.com/unpackdev/solgo"
	"github.com/unpackdev/solgo/utils"
	"go.uber.org/zap"
)

// Seek searches for contract source code based on network, block number, entry source name, and address.
// It logs the search process and returns the corresponding solgo.Sources if found.
func (s *Storage) Seek(ctx context.Context, network utils.Network, block *big.Int, entrySourceName string, addr common.Address) (*solgo.Sources, error) {
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
