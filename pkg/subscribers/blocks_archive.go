package subscribers

import (
	"context"
	"fmt"
	"github.com/ethereum/go-ethereum"
	"github.com/unpackdev/downloader/pkg/options"
	"github.com/unpackdev/solgo/clients"
	"go.uber.org/zap"
	"math/big"
	"sync"
)

var (
	ArchiveBlockSubscriber SubscriberType = "archive"
)

type ArchiveBlock struct {
	ctx    context.Context
	opts   *options.Subscriber
	pool   *clients.ClientPool
	status Status
	mu     sync.RWMutex
	sub    ethereum.Subscription // The Ethereum subscription object.
	hooks  map[HookType][]BlockHookFn
}

func NewArchiveBlock(ctx context.Context, pool *clients.ClientPool, opts *options.Subscriber, hooks map[HookType][]BlockHookFn) (*ArchiveBlock, error) {
	toReturn := &ArchiveBlock{
		ctx:   ctx,
		opts:  opts,
		pool:  pool,
		hooks: hooks,
		mu:    sync.RWMutex{},
	}
	return toReturn, nil
}

func (b *ArchiveBlock) Start() error {
	zap.L().Info(
		"Starting up block subscriber...",
		zap.Any("direction", ArchiveBlockSubscriber),
		zap.Bool("enabled", b.opts.Enabled),
		zap.Int("start_block_number", b.opts.StartBlockNumber),
		zap.Int("end_block_number", b.opts.EndBlockNumber),
	)

	if !b.opts.Enabled {
		return nil
	}

	client := b.pool.GetClientByGroup("ethereum")
	if client == nil {
		return fmt.Errorf("failure to get %s client from client pool", "ethereum")
	}

	b.status = StatusActive
	defer func() {
		b.status = StatusNotActive
	}()

	var mu sync.Mutex
	for i := b.opts.StartBlockNumber; i <= b.opts.EndBlockNumber; i++ {
		mu.Lock()
		block, err := client.BlockByNumber(b.ctx, big.NewInt(int64(i)))
		if err != nil {
			zap.L().Error(
				"Failed to get block by number",
				zap.Error(err),
				zap.Any("direction", ArchiveBlockSubscriber),
				zap.Int("block_number", i),
			)
			mu.Unlock()
			continue
		}

		for _, hook := range b.hooks[PostHook] {
			var err error
			block, err := hook(block)
			if err != nil {
				zap.L().Error(
					"failure to process post block hook",
					zap.Error(err),
					zap.Any("direction", ArchiveBlockSubscriber),
					zap.Uint64("header_number", block.NumberU64()),
					zap.String("header_hash", block.Hash().String()),
				)
				continue
			}
		}

	}

	return nil
}

func (b *ArchiveBlock) Stop() error {
	zap.L().Info("Stopping block subscriber...")
	return nil
}

func (b *ArchiveBlock) Status() Status {
	b.mu.RLock()
	defer b.mu.RUnlock()
	return b.status
}
