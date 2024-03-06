package state

import (
	"fmt"
	"math/big"
)

type Descriptor struct {
	CurrentBlockHeadNumber *big.Int
}

func (s *State) SetDescriptorKey(key Key, value any) error {
	switch key {
	case CurrentBlockHead:
		s.descriptor.CurrentBlockHeadNumber = value.(*big.Int)
		return nil
	default:
		return fmt.Errorf(
			"failure to set unknown state descriptor key '%s'",
			key.String(),
		)
	}
}

func (s *State) Descriptor() *Descriptor {
	return s.descriptor
}
