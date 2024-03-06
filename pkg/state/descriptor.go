package state

import (
	"context"
	"errors"
	"fmt"
	"github.com/redis/go-redis/v9"
	"math/big"
	"time"
)

type Descriptor struct {
	CurrentBlockHeadNumber      *big.Int
	LatestInspectedHeadBlock    *big.Int
	LatestInspectedArchiveBlock *big.Int
	StartBlockNumber            *big.Int
	EndBlockNumber              *big.Int
	PercentageCompleted         *big.Int
}

func (s *State) SetDescriptorKey(key Key, value any) error {
	switch key {
	case CurrentBlockHead:
		s.descriptor.CurrentBlockHeadNumber = value.(*big.Int)
		return nil
	case LatestInspectedHeadBlock:
		s.descriptor.LatestInspectedHeadBlock = value.(*big.Int)
		return nil
	case LatestInspectedArchiveBlock:
		s.descriptor.LatestInspectedArchiveBlock = value.(*big.Int)
		return nil
	case ArchiveStartBlockNumber:
		s.descriptor.StartBlockNumber = value.(*big.Int)
		return nil
	case ArchiveEndBlockNumber:
		s.descriptor.EndBlockNumber = value.(*big.Int)
		return nil
	default:
		return fmt.Errorf(
			"failure to set unknown state descriptor key '%s'",
			key.String(),
		)
	}
}

func (s *State) Load() error {
	ctx, cancel := context.WithTimeout(s.ctx, 5*time.Second)
	defer cancel()

	currentBlockHead, err := s.Get(ctx, CurrentBlockHead)
	if err != nil && !errors.Is(err, redis.Nil) {
		return err
	} else {
		s.descriptor.CurrentBlockHeadNumber = currentBlockHead
	}

	latestInspectedHeadBlock, err := s.Get(ctx, LatestInspectedHeadBlock)
	if err != nil && !errors.Is(err, redis.Nil) {
		return err
	} else {
		s.descriptor.LatestInspectedHeadBlock = latestInspectedHeadBlock
	}

	latestInspectedArchiveBlock, err := s.Get(ctx, LatestInspectedArchiveBlock)
	if err != nil && !errors.Is(err, redis.Nil) {
		return err
	} else {
		s.descriptor.LatestInspectedArchiveBlock = latestInspectedArchiveBlock
	}

	startBlockNumber, err := s.Get(ctx, ArchiveStartBlockNumber)
	if err != nil && !errors.Is(err, redis.Nil) {
		return err
	} else {
		s.descriptor.StartBlockNumber = startBlockNumber
	}

	endBlockNumber, err := s.Get(ctx, ArchiveEndBlockNumber)
	if err != nil && !errors.Is(err, redis.Nil) {
		return err
	} else {
		s.descriptor.EndBlockNumber = endBlockNumber
	}

	return nil
}

func (s *State) Descriptor() *Descriptor {
	// Ensure the necessary fields are not nil to avoid nil pointer dereferences.
	if s.descriptor.EndBlockNumber == nil || s.descriptor.LatestInspectedArchiveBlock == nil || s.descriptor.StartBlockNumber == nil {
		// Handle error or return the descriptor as-is if it's not possible to calculate the percentage.
		return s.descriptor
	}

	// Calculate the total range of blocks to inspect.
	totalBlocks := new(big.Int).Sub(s.descriptor.EndBlockNumber, s.descriptor.StartBlockNumber)

	// Calculate the number of blocks that have been inspected.
	inspectedBlocks := new(big.Int).Sub(s.descriptor.LatestInspectedArchiveBlock, s.descriptor.StartBlockNumber)

	// Multiply inspectedBlocks by 100 (to keep precision) and then divide by totalBlocks to get the percentage.
	// Note: This can result in a loss of precision for very large numbers or very small percentages.
	if totalBlocks.Sign() != 0 { // Avoid division by zero
		percentageCompleted := new(big.Int).Mul(inspectedBlocks, big.NewInt(100))
		percentageCompleted.Div(percentageCompleted, totalBlocks)

		s.descriptor.PercentageCompleted = percentageCompleted
	} else {
		// Handle the case where totalBlocks is 0 or negative, which might indicate an error in the block range.
		s.descriptor.PercentageCompleted = big.NewInt(0)
	}

	return s.descriptor
}
