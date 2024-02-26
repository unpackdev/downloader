package subscribers

import (
	"context"
	"fmt"
	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/unpackdev/solgo/clients"
	"go.uber.org/zap"
	"sync"
)

var (
	HeadBlockSubscriber SubscriberName = "head"
)

type Block struct {
	ctx    context.Context
	pool   *clients.ClientPool
	status Status
	mu     sync.RWMutex
	sub    ethereum.Subscription // The Ethereum subscription object.
	hooks  map[HookType][]BlockHookFn
}

func NewHeadBlock(ctx context.Context, pool *clients.ClientPool, hooks map[HookType][]BlockHookFn) (*Block, error) {
	toReturn := &Block{
		ctx:   ctx,
		pool:  pool,
		hooks: hooks,
		mu:    sync.RWMutex{},
	}
	return toReturn, nil
}

func (b *Block) Start() error {
	zap.L().Info("Starting up block subscriber...")

	client := b.pool.GetClientByGroup("ethereum")
	if client == nil {
		return fmt.Errorf("failure to get %s client from client pool", "ethereum")
	}

	headCh := make(chan *types.Header, 1)

	sub, err := client.SubscribeNewHead(b.ctx, headCh)
	if err != nil {
		return err
	}
	b.sub = sub

	for {
		select {
		case <-b.ctx.Done():
			b.sub.Unsubscribe()
			return nil
		case err := <-sub.Err():
			return err
		case header := <-headCh:
			block, err := client.BlockByHash(b.ctx, header.Hash())
			if err != nil {
				zap.L().Error(
					"Failed to get block by hash",
					zap.Error(err),
					zap.Uint64("header_number", header.Number.Uint64()),
					zap.String("header_hash", header.Hash().String()),
				)
				continue
			}

			for _, hook := range b.hooks[PostHook] {
				var err error
				block, err := hook(block)
				if err != nil {
					zap.L().Error(
						"failure to process post block hook",
						zap.Error(err),
						zap.Uint64("header_number", block.NumberU64()),
						zap.String("header_hash", block.Hash().String()),
					)
					continue
				}
			}
		}
	}
}

func (b *Block) Stop() error {
	zap.L().Info("Stopping block subscriber...")
	return nil
}

func (b *Block) Status() Status {
	b.mu.RLock()
	defer b.mu.RUnlock()
	return b.status
}
