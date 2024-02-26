package unpacker

import (
	"context"
	"github.com/unpackdev/downloader/pkg/machine"
)

type ProvidersContractHandler struct {
	ctx context.Context
	u   *Unpacker
}

func NewProvidersContractHandler(ctx context.Context, u *Unpacker) machine.Handler {
	bh := &ProvidersContractHandler{ctx: ctx, u: u}
	return machine.Handler{
		Enter:   bh.Enter,
		Process: bh.Process,
		Exit:    bh.Exit,
	}
}

func (dh *ProvidersContractHandler) Enter(data machine.Data) (machine.Data, error) {
	return data, nil
}

func (dh *ProvidersContractHandler) Process(data machine.Data) (machine.State, machine.Data, error) {
	descriptor := toDescriptor(data)

	// First we are going to check if dependency states are completed.
	if !descriptor.HasCompletedState(DiscoverState) {
		descriptor.SetNextState(MetadataState) // <- come back to this state afterward...
		return DiscoverState, descriptor, nil
	}

	descriptor.AppendCompletedState(SourceProvidersState)
	return SourcesState, descriptor, nil
}

func (dh *ProvidersContractHandler) Exit(data machine.Data) (machine.Data, error) {
	return data, nil
}
