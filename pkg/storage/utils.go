package storage

import (
	"fmt"
	"math/big"
	"path/filepath"

	"github.com/ethereum/go-ethereum/common"
	"github.com/unpackdev/solgo/utils"
)

// GetPathByNetworkAndBlockAndAddress constructs a file path for contract source files based on the network,
// block number, and contract address. It uses the configured contracts path in the storage options.
func (s *Storage) GetPathByNetworkAndBlockAndAddress(network utils.Network, block *big.Int, addr common.Address) string {
	return filepath.Join(s.opts.ContractsPath, fmt.Sprintf("_%s", network.String()), "mainnet", "contracts", block.String(), addr.String())
}
