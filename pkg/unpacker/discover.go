package unpacker

import (
	"context"
	"fmt"
	"github.com/unpackdev/downloader/pkg/machine"
)

type DiscoverContractHandler struct {
	ctx context.Context
	u   *Unpacker
}

func NewDiscoverContractHandler(ctx context.Context, u *Unpacker) machine.Handler {
	bh := &DiscoverContractHandler{ctx: ctx, u: u}
	return machine.Handler{
		Enter:   bh.Enter,
		Process: bh.Process,
		Exit:    bh.Exit,
	}
}

func (dh *DiscoverContractHandler) Enter(data machine.Data) (machine.Data, error) {
	return data, nil
}

func (dh *DiscoverContractHandler) Process(data machine.Data) (machine.State, machine.Data, error) {
	descriptor := toDescriptor(data)

	// First we are going to check if contract already exists in the database.
	// If it exists, we are going to skip this step and move forward...
	/*	if contracts.GetContract(descriptor.GetNetwork(), descriptor.GetAddr()) != nil {
		return MetadataState, descriptor, nil
	}*/

	/*	if !descriptor.HasNetworkModel() {
		return ErrorState, descriptor, fmt.Errorf(
			"contract %s does not have provided associated network model loaded from the database",
			descriptor.GetAddress().Hex(),
		)
	}*/

	if descriptor.GetHeader() == nil {
		return ErrorState, descriptor, fmt.Errorf(
			"contract %s does not have provided associated contract creation block",
			descriptor.GetAddr().Hex(),
		)
	}

	if descriptor.GetTransaction() == nil {
		return ErrorState, descriptor, fmt.Errorf(
			"contract %s does not have provided associated contract creation transaction",
			descriptor.GetAddr().Hex(),
		)
	}

	if descriptor.GetReceipt() == nil {
		return ErrorState, descriptor, fmt.Errorf(
			"contract %s does not have provided associated contract creation transaction receipt",
			descriptor.GetAddr().Hex(),
		)
	}

	/*	cache := dh.u.cacheClient
		dbAdapter := dh.u.dbAdapter.GetDb()
		block := descriptor.GetBlock()
		transaction := descriptor.GetTransaction()
		network := descriptor.GetNetwork()
		networkDb := descriptor.GetNetworkModel()

		// Superb... Now we can check if any of these exist in the database... If not, we can initiate creation process...

		// First we need to check if block exists in the database...
		if !descriptor.HasBlockModel() {
			dbBlock, err := models.GetBlockByNumber(dh.ctx, cache, dbAdapter, networkDb.UUID, descriptor.GetBlock().NumberU64())
			if err != nil {
				if !db.IsNotFound(err) {
					return ErrorState, descriptor, fmt.Errorf(
						"failed to fetch block %d from the database: %s",
						descriptor.GetBlock().NumberU64(),
						err.Error(),
					)
				}

				// It's not found error... Now we need to create new block here to ensure we can continue...
				model := &models.Block{
					UUID:             uuid.New(),
					NetworkUUID:      networkDb.UUID,
					Number:           block.NumberU64(),
					Hash:             block.Hash().Hex(),
					ParentHash:       block.ParentHash().Hex(),
					UncleHash:        block.UncleHash().Hex(),
					MixDigest:        block.MixDigest().Hex(),
					Nonce:            block.Nonce(),
					TransactionsRoot: block.Header().TxHash.Hex(),
					ReceiptsRoot:     block.Header().ReceiptHash.Hex(),
					LogsBloom:        block.Bloom().Bytes(),
					StateRoot:        block.Root().Hex(),
					Timestamp:        time.Unix(int64(block.Time()), 0),
					ExtraData:        block.Extra(),
					GasLimit:         block.GasLimit(),
					GasUsed:          block.GasUsed(),
					BaseFee: func() uint64 {
						if block.BaseFee() == nil {
							return 0
						}
						return block.BaseFee().Uint64()
					}(),
					Coinbase:         block.Coinbase().Hex(),
					Difficulty:       block.Difficulty().Uint64(),
					Size:             block.Size(),
					TransactionCount: uint64(len(block.Transactions())),
					CreatedAt:        time.Now().UTC(),
					UpdatedAt:        time.Now().UTC(),
				}

				if _, err := models.InsertBlock(dh.ctx, dbAdapter, model); err != nil {
					return ErrorState, descriptor, fmt.Errorf(
						"failed to insert block %d into the database: %s",
						descriptor.GetBlock().NumberU64(),
						err.Error(),
					)
				}

				descriptor.SetBlockModel(model)
			} else {
				descriptor.SetBlockModel(dbBlock)
			}
		}

		// Now we need to check if transaction exists in the database...
		if !descriptor.HasTransactionModel() {
			dbTransaction, err := models.GetTransactionByBlockAndHash(dh.ctx, cache, dbAdapter, networkDb.UUID, descriptor.GetTransaction().Hash())
			if err != nil {
				if !db.IsNotFound(err) {
					return ErrorState, descriptor, fmt.Errorf(
						"failed to fetch block %d transaction %v from the database: %s",
						descriptor.GetBlock().NumberU64(),
						descriptor.GetTransaction().Hash().Hex(),
						err.Error(),
					)
				}

				client := dh.u.clientsPool.GetClientByGroup(network.String())
				if client == nil {
					return ErrorState, descriptor, fmt.Errorf(
						"cannot discover client for network %s at block %d transaction %v",
						network.String(),
						descriptor.GetBlock().NumberU64(),
						descriptor.GetTransaction().Hash().Hex(),
					)
				}

				tx := &models.Transaction{
					UUID:             uuid.New(),
					NetworkUUID:      networkDb.UUID,
					BlockUUID:        descriptor.GetBlockModel().UUID,
					Hash:             transaction.Hash().Hex(),
					Nonce:            transaction.Nonce(),
					TransactionIndex: uint64(descriptor.GetReceipt().TransactionIndex),
					MethodType:       utils.ContractCreationType,
					RecipientAddress: utils.ZeroAddress.Hex(),
					RecipientType:    utils.ZeroAddressRecipient,
					Value:            transaction.Value().Uint64(),
					Cost:             transaction.Cost().Uint64(),
					GasPrice:         transaction.GasPrice().Uint64(),
					Gas:              transaction.Gas(),
					Status:           uint32(descriptor.GetReceipt().Status),
					ProcessedStates:  []machine.State{},
					FailedStates:     []machine.State{},
					CreatedAt:        time.Now().UTC(),
					UpdatedAt:        time.Now().UTC(),
				}

				from, err := types.Sender(types.LatestSignerForChainID(transaction.ChainId()), transaction)
				if err != nil {
					return ErrorState, descriptor, fmt.Errorf(
						"failed to fetch transaction %v sender: %s",
						descriptor.GetTransaction().Hash().Hex(),
						err.Error(),
					)
				}
				tx.SenderAddress = from.Hex()
				codeAt, _ := client.CodeAt(dh.ctx, from, block.Number())
				if len(codeAt) > 10 {
					tx.SenderType = utils.ContractRecipient
				} else {
					tx.SenderType = utils.AddressRecipient
				}

				if _, err := models.InsertTransaction(dh.ctx, dbAdapter, tx); err != nil {
					return ErrorState, descriptor, fmt.Errorf(
						"failed to insert block %d transaction %v into the database: %s",
						descriptor.GetBlock().NumberU64(),
						descriptor.GetTransaction().Hash().Hex(),
						err.Error(),
					)
				}
				descriptor.SetSenderAddress(from)
				descriptor.SetTransactionModel(tx)
			} else {
				descriptor.SetTransactionModel(dbTransaction)
			}
		}

		// Now we need to check if contract exists in the database...
		if !descriptor.HasContractModel() {
			dbContract, err := models.GetContract(dh.ctx, dbAdapter, networkDb.UUID, descriptor.GetAddress())
			if err != nil {
				if !db.IsNotFound(err) {
					return ErrorState, descriptor, fmt.Errorf(
						"failed to fetch contract %s from the database: %s",
						descriptor.GetAddress().Hex(),
						err.Error(),
					)
				}

				emptyJson, _ := utils.ToJSON("[]")
				model := &models.Contract{
					UUID:                   uuid.New(),
					NetworkUUID:            networkDb.UUID,
					BlockUUID:              descriptor.GetBlockModel().UUID,
					TransactionUUID:        descriptor.GetTransactionModel().UUID,
					Address:                descriptor.GetAddress().Hex(),
					CurrentProcessingState: DiscoverState.String(),
					NextProcessingState: func() string {
						if descriptor.HasNextState() {
							return descriptor.GetNextState().String()
						}
						return SourceProvidersState.String()
					}(),
					ProcessedStates: []machine.State{DiscoverState},
					FailedStates:    []machine.State{},
					SafetyState:     utils.UnknownSafetyState,
					ABI:             emptyJson,
					CreatedAt:       time.Now().UTC(),
					UpdatedAt:       time.Now().UTC(),
				}

				if _, err := models.InsertContract(dh.ctx, dbAdapter, model); err != nil {
					return ErrorState, descriptor, fmt.Errorf(
						"failed to insert contract %s into the database: %s",
						descriptor.GetAddress().Hex(),
						err.Error(),
					)
				}

				transactionUpdates := map[string]interface{}{
					"contract_uuid": model.UUID,
				}

				dbTransaction, err := models.UpdateTransaction(dh.ctx, dbAdapter, descriptor.GetTransactionModel().UUID, transactionUpdates)
				if err != nil {
					return ErrorState, descriptor, fmt.Errorf(
						"failed to update transaction %s with contract uuid: %s",
						descriptor.GetTransaction().Hash().Hex(),
						err.Error(),
					)
				}
				descriptor.SetTransactionModel(dbTransaction)
				descriptor.SetContractModel(model)
			} else {
				descriptor.SetContractModel(dbContract)
				descriptor.AppendCompletedStates(dbContract.ProcessedStates)
				descriptor.AppendFailedStates(dbContract.FailedStates)
			}
		}

		// Append completed state so we can on easy way figure out if we need to process this state or not in the future...
		// It's used when accessed state directly without first reaching discovery state.
		// In 99% of the cases, states will require this particular state to be resolved prior it can be processed...
		descriptor.AppendCompletedState(DiscoverState)

		zap.L().Debug(
			"Contract dependencies discovery state completed",
			zap.String("network", descriptor.GetNetwork().String()),
			zap.Any("network_id", descriptor.GetNetworkID()),
			zap.String("network_uuid", descriptor.GetNetworkModel().UUID.String()),
			zap.String("contract_address", descriptor.GetAddress().Hex()),
			zap.Uint64("block_number", descriptor.GetBlock().NumberU64()),
			zap.String("transaction_hash", descriptor.GetTransaction().Hash().Hex()),
		)

		// One change in direction... In case that there's a next state set on the descriptor, we are going to
		// ensure that we are going to move to that state instead of the default one and do it only once...
		// In this particular case we need this functionality as we can jump through the states. For example token needs to be processed
		// and that's accessed state but we do not have base information about contract. Thus this workaround.
		if descriptor.HasNextState() {
			nextState := descriptor.GetNextState()
			descriptor.SetNextState("")
			return nextState, descriptor, nil
		}
	*/

	// That's it. We've discovered and written all dependencies that we need to initiate actual processing of the contract...
	// Next step is about figuring out metadata and ipfs information (if available)...
	return MetadataState, descriptor, nil
}

func (dh *DiscoverContractHandler) Exit(data machine.Data) (machine.Data, error) {
	return data, nil
}
