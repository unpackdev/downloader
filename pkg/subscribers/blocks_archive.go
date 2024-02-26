package subscribers

import (
	"context"
	"fmt"
	"github.com/ethereum/go-ethereum"
	"github.com/unpackdev/solgo/clients"
	"go.uber.org/zap"
	"sync"
)

var (
	ArchiveBlockSubscriber SubscriberName = "archive"
)

type ArchiveBlock struct {
	ctx    context.Context
	pool   *clients.ClientPool
	status Status
	mu     sync.RWMutex
	sub    ethereum.Subscription // The Ethereum subscription object.
	hooks  map[HookType][]BlockHookFn
}

func NewArchiveBlock(ctx context.Context, pool *clients.ClientPool, hooks map[HookType][]BlockHookFn) (*Block, error) {
	toReturn := &Block{
		ctx:   ctx,
		pool:  pool,
		hooks: hooks,
		mu:    sync.RWMutex{},
	}
	return toReturn, nil
}

func (b *ArchiveBlock) Start() error {
	zap.L().Info("Starting up block subscriber...")

	client := b.pool.GetClientByGroup("ethereum")
	if client == nil {
		return fmt.Errorf("failure to get %s client from client pool", "ethereum")
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
