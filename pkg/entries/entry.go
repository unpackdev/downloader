package entries

import (
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/unpackdev/solgo/utils"
)

type Entry struct {
	Network    utils.Network      `json:"network"`
	NetworkID  utils.NetworkID    `json:"networkID"`
	Header     *types.Header      `json:"header"`
	SenderAddr common.Address     `json:"senderAddr"`
	Tx         *types.Transaction `json:"tx"`
	Receipt    *types.Receipt     `json:"receipt"`
}

type NotificationEntry struct {
	ChannelID string `json:"channelID"`
	Entry     *Entry `json:"entry"`
}
