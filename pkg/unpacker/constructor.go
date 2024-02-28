package unpacker

import (
	"context"
	"github.com/unpackdev/inspector/pkg/machine"
	"go.uber.org/zap"
)

type ConstructorContractHandler struct {
	ctx context.Context
	u   *Unpacker
}

func NewConstructorContractHandler(ctx context.Context, u *Unpacker) machine.Handler {
	bh := &ConstructorContractHandler{ctx: ctx, u: u}
	return machine.Handler{
		Enter:   bh.Enter,
		Process: bh.Process,
		Exit:    bh.Exit,
	}
}

func (dh *ConstructorContractHandler) Enter(data machine.Data) (machine.Data, error) {
	return data, nil
}

func (dh *ConstructorContractHandler) Process(data machine.Data) (machine.State, machine.Data, error) {
	descriptor := toDescriptor(data)
	cdescriptor := descriptor.GetContract().GetDescriptor()
	contract := descriptor.GetContract()

	// First we are going to check if dependency states are completed.
	if !descriptor.HasCompletedState(DiscoverState) {
		descriptor.SetNextState(MetadataState) // <- We won't go to this state until we complete the dependency state.
		return DiscoverState, descriptor, nil
	}

	if cdescriptor.HasDetector() {
		irRoot := cdescriptor.GetDetector().GetIR().GetRoot()

		if irRoot.GetEntryContract() != nil && irRoot.GetEntryContract().GetConstructor() != nil {
			//constructorAst, _ := utils.ToJSON(irRoot.GetEntryContract().GetConstructor())
			if err := contract.DiscoverConstructor(dh.ctx); err != nil {
				zap.L().Debug(
					"failed to discover constructor from contract deployed code",
					zap.Error(err),
					zap.String("network", descriptor.GetNetwork().String()),
					zap.Any("network_id", descriptor.GetNetworkID()),
					zap.String("contract_address", descriptor.GetAddr().Hex()),
					zap.Uint64("block_number", descriptor.GetHeader().Number.Uint64()),
					zap.String("transaction_hash", descriptor.GetTransaction().Hash().Hex()),
					zap.String("source_provider", cdescriptor.GetSourcesProvider()),
				)
			}

		}
	}

	return FinalState, descriptor, nil
}

func (dh *ConstructorContractHandler) Exit(data machine.Data) (machine.Data, error) {
	return data, nil
}
