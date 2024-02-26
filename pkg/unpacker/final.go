package unpacker

import (
	"context"
	"github.com/unpackdev/downloader/pkg/machine"
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
	// First we are going to check if dependency states are completed.
	if !descriptor.HasCompletedState(DiscoverState) {
		descriptor.SetNextState(MetadataState) // <- come back to this state afterward...
		return DiscoverState, descriptor, nil
	}

	descriptor.AppendCompletedState(FinalState)
	return DoneState, descriptor, nil
}

func (dh *FinalContractHandler) Exit(data machine.Data) (machine.Data, error) {
	return data, nil
}
