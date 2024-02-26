package syncer

import (
	"context"
	"github.com/unpackdev/downloader/pkg/entries"
	"github.com/unpackdev/downloader/pkg/machine"
	"github.com/unpackdev/downloader/pkg/unpacker"
	"github.com/urfave/cli/v2"
	"go.uber.org/zap"
)

// Unpack ...
// @TODO: Implement UnpackFromEntry here with custom Entry... Should reuse code.
func (s *Service) Unpack(ctx *cli.Context) error {
	return nil
}

func (s *Service) UnpackFromEntry(ctx context.Context, entry *entries.Entry, state machine.State) (*unpacker.Descriptor, error) {
	// Basically, SolGo AST parser can panic in time to time...
	// What we want here is to capture these events and as well to report them as critical later on
	// with grafana/prom/loki being up...
	defer func(cloneEntry *entries.Entry) {
		if r := recover(); r != nil {
			zap.L().Error(
				"Recovered from panic in contract unpacking process...",
				zap.Any("panic", r),
				zap.Any("network", cloneEntry.Network),
				zap.Any("contract_address", cloneEntry.ContractAddr),
				zap.Uint64("contract_block_number", cloneEntry.Header.Number.Uint64()),
				zap.String("contract_tx_hash", cloneEntry.Tx.Hash().Hex()),
			)
		}
	}(entry)

	descriptor, err := s.unpacker.Unpack(ctx, entry.GetDescriptor(s.unpacker), state)
	if err != nil {
		return nil, err
	}

	return descriptor, nil
}
