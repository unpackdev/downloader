package unpacker

import (
	"context"
	"github.com/unpackdev/downloader/pkg/machine"
	"go.uber.org/zap"
)

type FinalContractHandler struct {
	ctx context.Context
	u   *Unpacker
}

func NewFinalContractHandler(ctx context.Context, u *Unpacker) machine.Handler {
	bh := &FinalContractHandler{ctx: ctx, u: u}
	return machine.Handler{
		Enter:   bh.Enter,
		Process: bh.Process,
		Exit:    bh.Exit,
	}
}

func (dh *FinalContractHandler) Enter(data machine.Data) (machine.Data, error) {
	return data, nil
}

func (dh *FinalContractHandler) Process(data machine.Data) (machine.State, machine.Data, error) {
	descriptor := toDescriptor(data)
	cdescriptor := descriptor.GetContract().GetDescriptor()

	// First we are going to check if dependency states are completed.
	if !descriptor.HasCompletedState(DiscoverState) {
		descriptor.SetNextState(MetadataState) // <- come back to this state afterward...
		return DiscoverState, descriptor, nil
	}

	entry := descriptor.GetStorageEntry()

	if cdescriptor.HasSources() {

		if err := dh.u.storage.Save(dh.ctx, entry, descriptor.GetContract().GetDescriptor().GetSources()); err != nil {
			zap.L().Error(
				"failed to parse contract",
				zap.Error(err),
				zap.String("network", descriptor.GetNetwork().String()),
				zap.Any("network_id", descriptor.GetNetworkID()),
				zap.String("contract_address", descriptor.GetAddr().Hex()),
				zap.Uint64("block_number", descriptor.GetHeader().Number.Uint64()),
				zap.String("transaction_hash", descriptor.GetTransaction().Hash().Hex()),
				zap.String("source_provider", cdescriptor.GetSourcesProvider()),
			)
			descriptor.AppendFailedState(FinalState)
		}
	}

	if !descriptor.HasFailedState(FinalState) {
		descriptor.AppendCompletedState(FinalState)
	}

	return DoneState, descriptor, nil
}

func (dh *FinalContractHandler) Exit(data machine.Data) (machine.Data, error) {
	return data, nil
}
