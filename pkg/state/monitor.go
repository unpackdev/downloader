package state

import (
	"context"
	"go.uber.org/zap"
	"time"
)

func (s *State) Monitor(ctx context.Context) error {
	zap.L().Info("Starting up state monitoring package...")

	ticker := time.NewTicker(3 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return nil
		case <-ticker.C:
			currentState := s.Descriptor()
			zap.L().Info(
				"Synchronization state report",
				zap.Any("current_head_block_number", currentState.CurrentBlockHeadNumber),
			)
			ticker.Reset(3 * time.Second)
		}
	}
}
