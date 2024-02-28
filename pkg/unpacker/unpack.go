package unpacker

import (
	"context"
	"fmt"
	"github.com/unpackdev/inspector/pkg/machine"
	"go.uber.org/zap"
)

func (u *Unpacker) Unpack(ctx context.Context, descriptor *Descriptor, state machine.State) (*Descriptor, error) {
	sm := machine.NewStateMachine(ctx, state, descriptor)
	if err := u.RegisterMachineStates(sm); err != nil {
		zap.L().Error(
			"Failed to setup contract unpacking state machine",
			zap.Error(err),
			zap.Any("network", descriptor.Network),
			zap.Any("network_id", descriptor.NetworkID),
			zap.String("contract_address", descriptor.Addr.Hex()),
			zap.Any("initial_state", state),
		)
		return nil, err
	}

	if err := sm.Process(); err != nil {
		zap.L().Error(
			"Failed to process contract unpacking state machine",
			zap.Error(err),
			zap.Any("network", descriptor.Network),
			zap.Any("network_id", descriptor.NetworkID),
			zap.String("contract_address", descriptor.Addr.Hex()),
			zap.Any("initial_state", state),
		)
		return nil, fmt.Errorf("failed to process contract unpacking state machine: %s", err)
	}

	return descriptor, nil
}
