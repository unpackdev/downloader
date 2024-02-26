package unpacker

import (
	"github.com/unpackdev/downloader/pkg/machine"
)

func (u *Unpacker) RegisterMachineStates(sm *machine.StateMachine) error {
	//sm.RegisterState(unpacker.DiscoverState, unpacker.NewDiscoverContractHandler(u.ctx, u))
	return nil
}
