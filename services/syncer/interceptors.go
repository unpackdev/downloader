package syncer

import (
	"fmt"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/unpackdev/solgo/utils"
	"go.uber.org/zap"
)

// BlockInterceptor -
// @TODO: Ethereum cannot be hardcoded here... For now it is, in the future diff networks should be accepted.
func BlockInterceptor(srv *Service) func(block *types.Block) (*types.Block, error) {
	return func(block *types.Block) (*types.Block, error) {
		zap.L().Debug(
			"Received new blockchain block",
			zap.Uint64("header_number", block.NumberU64()),
			zap.String("header_hash", block.Hash().String()),
		)

		for _, tx := range block.Transactions() {
			from, err := types.Sender(types.LatestSignerForChainID(tx.ChainId()), tx)
			if err != nil {
				zap.L().Error(
					"Failed to get transaction sender",
					zap.Error(err),
					zap.Uint64("header_number", block.NumberU64()),
					zap.String("header_hash", block.Hash().String()),
					zap.String("tx_hash", tx.Hash().String()),
				)
				continue
			}

			client := srv.pool.GetClientByGroup(utils.Ethereum.String())
			if client == nil {
				return block, fmt.Errorf(
					"failure to discover '%s' client - rejecting ransaction processing",
					utils.Ethereum.String(),
				)
			}

			_ = from

			// Passing in all the arguments to the goroutine to ensure there are no shadowing going on
			/*			go func(srv *Service, entry *watchers.Entry) {
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
								zap.Uint64("header_number", entry.Header.Number.Uint64()),
								zap.String("header_hash", entry.Header.Hash().String()),
								zap.String("tx_hash", entry.Tx.Hash().String()),
							)
							return
						}

						entry.Receipt = receipt

					}(srv, entry)*/
		}

		return block, nil
	}
}
