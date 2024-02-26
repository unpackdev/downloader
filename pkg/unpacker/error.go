package unpacker

import (
	"context"
	"github.com/unpackdev/downloader/pkg/machine"
)

type ErrorContractHandler struct {
	ctx context.Context
	u   *Unpacker
}

func NewErrorContractHandler(ctx context.Context, u *Unpacker) machine.Handler {
	bh := &ErrorContractHandler{ctx: ctx, u: u}
	return machine.Handler{
		Enter:   bh.Enter,
		Process: bh.Process,
		Exit:    bh.Exit,
	}
}

func (dh *ErrorContractHandler) Enter(data machine.Data) (machine.Data, error) {
	return data, nil
}

func (dh *ErrorContractHandler) Process(data machine.Data) (machine.State, machine.Data, error) {
	descriptor := toDescriptor(data)

	return DoneState, descriptor, nil
}

func (dh *ErrorContractHandler) Exit(data machine.Data) (machine.Data, error) {
	return data, nil
}
