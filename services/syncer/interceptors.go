package syncer

import (
	"context"
	"fmt"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/unpackdev/inspector/pkg/entries"
	"github.com/unpackdev/inspector/pkg/unpacker"
	"github.com/unpackdev/solgo/utils"
	"go.uber.org/zap"
	"time"
)

type SyncDirection string

func (s SyncDirection) String() string {
	return string(s)
}

var (
	HeadSyncDirection    SyncDirection = "head"
	ArchiveSyncDirection SyncDirection = "archive"
)

// BlockInterceptor -
func BlockInterceptor(srv *Service, network utils.Network, networkId utils.NetworkID, direction SyncDirection) func(block *types.Block) (*types.Block, error) {
	return func(block *types.Block) (*types.Block, error) {
		zap.L().Debug(
			"Received new blockchain block",
			zap.Any("network", network),
			zap.Any("network_id", networkId),
			zap.Any("direction", direction),
			zap.Uint64("header_number", block.NumberU64()),
			zap.String("header_hash", block.Hash().String()),
		)

		for _, tx := range block.Transactions() {
			from, err := types.Sender(types.LatestSignerForChainID(tx.ChainId()), tx)
			if err != nil {
				zap.L().Error(
					"Failed to get transaction sender",
					zap.Error(err),
					zap.Any("network", network),
					zap.Any("network_id", networkId),
					zap.Any("direction", direction),
					zap.Uint64("header_number", block.NumberU64()),
					zap.String("header_hash", block.Hash().String()),
					zap.String("tx_hash", tx.Hash().String()),
				)
				continue
			}

			// We are not interested in transactions that are not related to the smart contracts
			// themselves. Only new smart contract deployment transactions shall pass...
			if tx.To() != nil {
				continue
			}

			client := srv.pool.GetClientByGroup(network.String())
			if client == nil {
				return block, fmt.Errorf(
					"failure to discover '%s' client - rejecting ransaction processing",
					network.String(),
				)
			}

			entry := &entries.Entry{
				Network:     network,
				NetworkID:   networkId,
				CreatorAddr: from,
				Header:      block.Header(),
				Tx:          tx,
			}

			// Passing in all the arguments to the goroutine to ensure there are no shadowing going on
			go func(srv *Service, entry *entries.Entry) {
				// Alright, lets grab all the receipts... As it's local erigon it will be fast.
				// Not really the best solution ATM as better would be to spawn goroutines handling
				// all the receipts but heck...
				// @TODO: Replace this with more appropriate OTS (otterscan) erigon solution where
				// transactions and receipts can be obtained from a single call.
				receipt, err := client.Client.TransactionReceipt(srv.ctx, entry.Tx.Hash())
				if err != nil {
					zap.L().Error(
						"Failed to get transaction receipt",
						zap.Error(err),
						zap.Any("network", network),
						zap.Any("network_id", networkId),
						zap.Any("direction", direction),
						zap.Uint64("header_number", entry.Header.Number.Uint64()),
						zap.String("header_hash", entry.Header.Hash().String()),
						zap.String("tx_hash", entry.Tx.Hash().String()),
					)
					return
				}

				entry.Receipt = receipt
				entry.ContractAddr = receipt.ContractAddress

				zap.L().Debug(
					"Processing new smart contract",
					zap.Any("network", network),
					zap.Any("network_id", networkId),
					zap.Any("direction", direction),
					zap.Uint64("header_number", entry.Header.Number.Uint64()),
					zap.String("header_hash", entry.Header.Hash().String()),
					zap.String("tx_hash", entry.Tx.Hash().String()),
					zap.String("address", receipt.ContractAddress.Hex()),
				)

				// Making sure we don't hang forever in case of hard unpack hangs...
				ctx, cancel := context.WithTimeout(srv.ctx, 30*time.Second)
				defer cancel()

				descriptor, err := srv.UnpackFromEntry(ctx, entry, unpacker.DiscoverState)
				if err != nil {
					zap.L().Error(
						"failure to unpack contract entry",
						zap.Error(err),
						zap.Any("network", network),
						zap.Any("network_id", networkId),
						zap.Any("direction", direction),
						zap.Uint64("header_number", entry.Header.Number.Uint64()),
						zap.String("header_hash", entry.Header.Hash().String()),
						zap.String("tx_hash", entry.Tx.Hash().String()),
						zap.String("address", receipt.ContractAddress.Hex()),
					)
					return
				}

				zap.L().Debug(
					"Successful new contract entry unpack",
					zap.Any("network", network),
					zap.Any("network_id", networkId),
					zap.Any("direction", direction),
					zap.Uint64("header_number", entry.Header.Number.Uint64()),
					zap.String("header_hash", entry.Header.Hash().String()),
					zap.String("tx_hash", entry.Tx.Hash().String()),
					zap.String("address", receipt.ContractAddress.Hex()),
				)

				// @TODO: Peer to Peer delivery should be potentially executed here...
				// Basically if one peer handles it, it can send it to the "sequencer"
				// that is going to save the data into the database...
				// No public nodes for now which makes things easier to deal with.
				_ = descriptor

			}(srv, entry)
		}

		return block, nil
	}
}
