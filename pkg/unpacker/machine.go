package unpacker

import (
	"github.com/unpackdev/downloader/pkg/machine"
)

func (u *Unpacker) RegisterMachineStates(sm *machine.StateMachine) error {
	sm.RegisterState(DiscoverState, NewDiscoverContractHandler(u.ctx, u))
	sm.RegisterState(MetadataState, NewMetadataContractHandler(u.ctx, u))
	sm.RegisterState(SourceProvidersState, NewProvidersContractHandler(u.ctx, u))
	sm.RegisterState(SourcesState, NewSourcesContractHandler(u.ctx, u))
	sm.RegisterState(ParserState, NewParserContractHandler(u.ctx, u))

	// Special case: ERROR
	sm.RegisterState(ErrorState, NewErrorContractHandler(u.ctx, u))
	if err := sm.RegisterErrorState(ErrorState); err != nil {
		return err
	}

	// Special case: DONE
	sm.RegisterState(FinalState, NewFinalContractHandler(u.ctx, u))
	if err := sm.RegisterFinalState(DoneState); err != nil {
		return err
	}

	return nil
}
