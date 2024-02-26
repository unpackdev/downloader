package unpacker

import (
	"context"
	"github.com/unpackdev/downloader/pkg/machine"
	"go.uber.org/zap"
	"strings"
)

type ParserContractHandler struct {
	ctx context.Context
	u   *Unpacker
}

func NewParserContractHandler(ctx context.Context, u *Unpacker) machine.Handler {
	bh := &ParserContractHandler{ctx: ctx, u: u}
	return machine.Handler{
		Enter:   bh.Enter,
		Process: bh.Process,
		Exit:    bh.Exit,
	}
}

func (dh *ParserContractHandler) Enter(data machine.Data) (machine.Data, error) {
	return data, nil
}

func (dh *ParserContractHandler) Process(data machine.Data) (machine.State, machine.Data, error) {
	descriptor := toDescriptor(data)

	// First we are going to check if dependency states are completed.
	if !descriptor.HasCompletedState(DiscoverState) {
		descriptor.SetNextState(MetadataState) // <- come back to this state afterward...
		return DiscoverState, descriptor, nil
	}

	if descriptor.GetContract().GetDescriptor().HasSources() {
		if err := descriptor.GetContract().Parse(dh.ctx); err != nil {
			if !strings.Contains(err.Error(), "not supported compiler version") {
				zap.L().Error(
					"failed to parse contract",
					zap.Error(err),
					zap.String("network", descriptor.GetNetwork().String()),
					zap.Any("network_id", descriptor.GetNetworkID()),
					zap.String("contract_address", descriptor.GetAddr().Hex()),
					zap.Uint64("block_number", descriptor.GetHeader().Number.Uint64()),
					zap.String("transaction_hash", descriptor.GetTransaction().Hash().Hex()),
					zap.String("source_provider", descriptor.GetContract().GetDescriptor().GetSourcesProvider()),
				)
			}
			descriptor.AppendFailedState(ParserState)
		} else {
			descriptor.RemoveFailedState(ParserState)
			descriptor.AppendCompletedState(ParserState)
		}
	}

	if !descriptor.HasFailedState(ParserState) {
		descriptor.AppendCompletedState(ParserState)
	}

	return FinalState, descriptor, nil
}

func (dh *ParserContractHandler) Exit(data machine.Data) (machine.Data, error) {
	return data, nil
}
