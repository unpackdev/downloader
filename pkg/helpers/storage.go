package helpers

import (
	"fmt"
	"github.com/ethereum/go-ethereum/common"
	"github.com/unpackdev/solgo/utils"
	"path/filepath"
	"strings"
)

func GetStorageCachePath(network utils.Network, blockNumber string, addr common.Address) string {
	return filepath.Join(
		fmt.Sprintf("_%s", strings.ToLower(network.String())),
		// This is hardcoded for now... Not sure if I personally ever want to support testnet contracts
		"mainnet",
		// It will always be contracts and nothing else, therefore, hand-coded.
		"contracts",
		blockNumber,
		addr.Hex(),
	)
}
