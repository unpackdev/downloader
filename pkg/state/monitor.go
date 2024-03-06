package state

import (
	"context"
	"go.uber.org/zap"
	"time"
)

func (s *State) Monitor(ctx context.Context) error {
	zap.L().Info("Starting up state monitoring package...")
	tickDuration := time.Duration(10 * time.Second)
	ticker := time.NewTicker(tickDuration)
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
				zap.Any("latest_inspected_head_block_number", currentState.LatestInspectedHeadBlock),
				zap.Any("start_archive_block", currentState.StartBlockNumber),
				zap.Any("current_archive_block", currentState.LatestInspectedArchiveBlock),
				zap.Any("end_archive_block", currentState.EndBlockNumber),
				zap.Any("percentage_completed", currentState.PercentageCompleted),
			)
			ticker.Reset(tickDuration)
		}
	}
}
