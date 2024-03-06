package unpacker

import (
	"context"
	"github.com/unpackdev/inspector/pkg/machine"
	"go.uber.org/zap"
	"strings"
)

type MetadataContractHandler struct {
	ctx context.Context
	u   *Unpacker
}

func NewMetadataContractHandler(ctx context.Context, u *Unpacker) machine.Handler {
	bh := &MetadataContractHandler{ctx: ctx, u: u}
	return machine.Handler{
		Enter:   bh.Enter,
		Process: bh.Process,
		Exit:    bh.Exit,
	}
}

func (dh *MetadataContractHandler) Enter(data machine.Data) (machine.Data, error) {
	return data, nil
}

func (dh *MetadataContractHandler) Process(data machine.Data) (machine.State, machine.Data, error) {
	descriptor := toDescriptor(data)

	// First we are going to check if dependency states are completed.
	if !descriptor.HasCompletedState(DiscoverState) {
		descriptor.SetNextState(MetadataState) // <- come back to this state afterward...
		return DiscoverState, descriptor, nil
	}

	contract := descriptor.GetContract()
	cdescriptor := contract.GetDescriptor()

	if cdescriptor != nil && !descriptor.SelfDestructed && !cdescriptor.HasMetadata() {
		_, err := contract.DiscoverMetadata(dh.ctx)
		if err != nil {
			if !strings.Contains(err.Error(), "provided bytecode slice is smaller than the length") {
				zap.L().Error(
					"failed to decode bytecode metadata from contract deployed code",
					zap.Error(err),
					zap.String("network", descriptor.GetNetwork().String()),
					zap.Any("network_id", descriptor.GetNetworkID()),
					zap.String("contract_address", descriptor.GetAddr().Hex()),
					zap.Uint64("block_number", descriptor.GetHeader().Number.Uint64()),
					zap.String("transaction_hash", descriptor.GetTransaction().Hash().Hex()),
					zap.String("source_provider", cdescriptor.GetSourcesProvider()),
				)
			}
			descriptor.AppendFailedState(MetadataState)
		}
	}

	if !descriptor.HasFailedState(MetadataState) {
		descriptor.AppendCompletedState(MetadataState)
	}

	return SourceProvidersState, descriptor, nil
}

func (dh *MetadataContractHandler) Exit(data machine.Data) (machine.Data, error) {
	return data, nil
}
