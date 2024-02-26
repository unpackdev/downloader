package unpacker

import (
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/unpackdev/solgo/utils"
)

type Descriptor struct {
	Network   utils.Network
	NetworkID utils.NetworkID
	Addr      common.Address
	Header    *types.Header
	Tx        *types.Transactions
	Receipt   *types.Receipt
}
