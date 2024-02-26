package unpacker

import (
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/unpackdev/downloader/pkg/machine"
	"github.com/unpackdev/solgo/utils"
)

type Descriptor struct {
	unpacker  *Unpacker
	Network   utils.Network
	NetworkID utils.NetworkID
	Addr      common.Address
	Header    *types.Header
	Tx        *types.Transaction
	Receipt   *types.Receipt

	// States...
	nextState       machine.State
	completedStates []machine.State
	failedStates    []machine.State
}

func NewDescriptor(u *Unpacker, network utils.Network, networkId utils.NetworkID, addr common.Address) *Descriptor {
	return &Descriptor{
		unpacker:        u,
		Network:         network,
		NetworkID:       networkId,
		Addr:            addr,
		completedStates: make([]machine.State, 0),
		failedStates:    make([]machine.State, 0),
	}
}

func (d *Descriptor) GetUnpacker() *Unpacker {
	return d.unpacker
}

func (d *Descriptor) GetNetwork() utils.Network {
	return d.Network
}

func (d *Descriptor) GetNetworkID() utils.NetworkID {
	return d.NetworkID
}

func (d *Descriptor) GetAddr() common.Address {
	return d.Addr
}

func (d *Descriptor) GetHeader() *types.Header {
	return d.Header
}

func (d *Descriptor) GetTransaction() *types.Transaction {
	return d.Tx
}

func (d *Descriptor) GetReceipt() *types.Receipt {
	return d.Receipt
}

// STATE MANAGEMENT

func (d *Descriptor) HasNextState() bool {
	return d.nextState != ""
}

func (d *Descriptor) GetNextState() machine.State {
	return d.nextState
}

func (d *Descriptor) SetNextState(state machine.State) {
	d.nextState = state
}

func (d *Descriptor) HasCompletedState(state machine.State) bool {
	for _, s := range d.completedStates {
		if s == state {
			return true
		}
	}

	return false
}

func (d *Descriptor) GetCompletedStates() []machine.State {
	return d.completedStates
}

func (d *Descriptor) AppendCompletedState(state machine.State) {
	for _, s := range d.completedStates {
		if s == state {
			return
		}
	}

	d.completedStates = append(d.completedStates, state)
}

func (d *Descriptor) AppendCompletedStates(states []machine.State) {
	for _, state := range states {
		d.AppendCompletedState(state)
	}
}

func (d *Descriptor) HasFailedState(state machine.State) bool {
	for _, s := range d.failedStates {
		if s == state {
			return true
		}
	}

	return false
}

func (d *Descriptor) GetFailedStates() []machine.State {
	return d.failedStates
}

func (d *Descriptor) AppendFailedState(state machine.State) {
	for _, s := range d.failedStates {
		if s == state {
			return
		}
	}

	d.failedStates = append(d.failedStates, state)
}

func (d *Descriptor) RemoveFailedState(state machine.State) {
	var newFailedStates []machine.State
	for _, s := range d.failedStates {
		if s != state {
			newFailedStates = append(newFailedStates, s)
		}
	}
	d.failedStates = newFailedStates
}

func (d *Descriptor) AppendFailedStates(states []machine.State) {
	for _, state := range states {
		d.AppendFailedState(state)
	}
}

func (d *Descriptor) RemoveFailedStates(states []machine.State) {
	for _, state := range states {
		d.RemoveFailedState(state)
	}
}

func toDescriptor(data machine.Data) *Descriptor {
	return data.(*Descriptor)
}
