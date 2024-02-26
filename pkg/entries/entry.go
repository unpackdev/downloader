package entries

import (
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/unpackdev/downloader/pkg/unpacker"
	"github.com/unpackdev/solgo/contracts"
	"github.com/unpackdev/solgo/utils"
)

type Entry struct {
	Network      utils.Network      `json:"network"`
	NetworkID    utils.NetworkID    `json:"networkID"`
	Header       *types.Header      `json:"header"`
	CreatorAddr  common.Address     `json:"creatorAddr"`
	Tx           *types.Transaction `json:"tx"`
	Receipt      *types.Receipt     `json:"receipt"`
	ContractAddr common.Address     `json:"contractAddr"`
}

func (e *Entry) GetDescriptor(u *unpacker.Unpacker, c *contracts.Contract) *unpacker.Descriptor {
	toReturn := unpacker.NewDescriptor(
		u,
		e.Network,
		e.NetworkID,
		e.ContractAddr,
	)
	toReturn.Header = e.Header
	toReturn.Tx = e.Tx
	toReturn.Receipt = e.Receipt

	// Set the contract. Not important right now if it's nil or not...
	toReturn.SetContract(c)

	return toReturn
}

type NotificationEntry struct {
	ChannelID string `json:"channelID"`
	Entry     *Entry `json:"entry"`
}
