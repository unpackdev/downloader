package unpacker

import (
	"context"
	"github.com/unpackdev/downloader/pkg/machine"
)

type SourcesContractHandler struct {
	ctx context.Context
	u   *Unpacker
}

func NewSourcesContractHandler(ctx context.Context, u *Unpacker) machine.Handler {
	bh := &SourcesContractHandler{ctx: ctx, u: u}
	return machine.Handler{
		Enter:   bh.Enter,
		Process: bh.Process,
		Exit:    bh.Exit,
	}
}

func (dh *SourcesContractHandler) Enter(data machine.Data) (machine.Data, error) {
	return data, nil
}

func (dh *SourcesContractHandler) Process(data machine.Data) (machine.State, machine.Data, error) {
	descriptor := toDescriptor(data)

	return FinalState, descriptor, nil
}

func (dh *SourcesContractHandler) Exit(data machine.Data) (machine.Data, error) {
	return data, nil
}
