package unpacker

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"github.com/unpackdev/inspector/pkg/machine"
	"github.com/unpackdev/inspector/pkg/models"
	"github.com/unpackdev/inspector/pkg/options"
	"go.uber.org/zap"
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

	descriptorContract := descriptor.GetContract()
	if descriptorContract != nil {
		valid, _ := descriptorContract.IsValid()
		descriptor.SelfDestructed = valid == false
	}

	// Now it's time to attempt to discover contract from the storage
	contract, err := models.GetContractByUniqueIndex(dh.u.db.GetDB(), descriptor.NetworkID.ToBig(), descriptor.GetHeader().Number, descriptor.GetAddr())
	if err != nil {
		if !errors.Is(err, sql.ErrNoRows) {
			zap.L().Error(
				"failed to fetch contract from the storage",
				zap.Error(err),
				zap.String("network", descriptor.GetNetwork().String()),
				zap.Any("network_id", descriptor.GetNetworkID()),
				zap.String("contract_address", descriptor.GetAddr().Hex()),
				zap.Uint64("block_number", descriptor.GetHeader().Number.Uint64()),
				zap.String("transaction_hash", descriptor.GetTransaction().Hash().Hex()),
				zap.String("source_provider", descriptor.GetContract().GetDescriptor().GetSourcesProvider()),
			)
			return ErrorState, descriptor, err
		}
	}
	descriptor.SetContractModel(contract)

	// Now we want to make sure that we're not processing again contracts that are
	// already processed unless configuration is set to reprocess all the contracts
	// regardless of their state...
	if contract != nil && contract.IsCompleted() {
		if !options.G().Unpacker.ForceReprocess {
			zap.L().Warn("Contract already processed....")
			return DoneState, descriptor, nil
		}
	}

	// Append completed state, so we can on easy way figure out if we need to process this state or not in the future...
	// It's used when accessed state directly without first reaching discovery state.
	// In 99% of the cases, states will require this particular state to be resolved prior it can be processed...
	descriptor.AppendCompletedState(DiscoverState)

	zap.L().Debug(
		"Contract dependencies discovery state completed",
		zap.Any("network", descriptor.GetNetwork()),
		zap.Any("network_id", descriptor.GetNetworkID()),
		zap.String("contract_address", descriptor.GetAddr().Hex()),
		zap.Uint64("block_number", descriptor.GetHeader().Number.Uint64()),
		zap.String("transaction_hash", descriptor.GetTransaction().Hash().Hex()),
	)

	// One change in direction... In case that there's a next state set on the descriptor, we are going to
	// ensure that we are going to move to that state instead of the default one and do it only once...
	// In this particular case we need this functionality as we can jump through the states. For example token needs to be processed
	// and that's accessed state, but we do not have base information about contract. Thus, this workaround.
	if descriptor.HasNextState() {
		nextState := descriptor.GetNextState()
		descriptor.SetNextState("")
		return nextState, descriptor, nil
	}

	// That's it. We've discovered and written all dependencies that we need to initiate actual processing of the contract...
	// Next step is about figuring out metadata and ipfs information (if available)...
	return MetadataState, descriptor, nil
}

func (dh *DiscoverContractHandler) Exit(data machine.Data) (machine.Data, error) {
	return data, nil
}
