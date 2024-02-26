package unpacker

import (
	"context"
	"github.com/unpackdev/downloader/pkg/machine"
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

	return SourceProvidersState, descriptor, nil
}

func (dh *MetadataContractHandler) Exit(data machine.Data) (machine.Data, error) {
	return data, nil
}
