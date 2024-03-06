package subscribers

import (
	"context"
	"fmt"
	"github.com/ethereum/go-ethereum"
	"github.com/unpackdev/inspector/pkg/options"
	"github.com/unpackdev/inspector/pkg/state"
	"github.com/unpackdev/solgo/clients"
	"github.com/unpackdev/solgo/utils"
	"go.uber.org/zap"
	"math/big"
	"sync"
)

// ArchiveBlockSubscriber defines the subscriber type for archive blocks.
var ArchiveBlockSubscriber SubscriberType = "archive"

// ArchiveBlock represents a subscription to a range of Ethereum archive blocks.
// It facilitates the execution of predefined hooks on each block within the specified range.
type ArchiveBlock struct {
	ctx    context.Context     // Context for managing the lifecycle of the subscription.
	opts   *options.Subscriber // Options defining the range of blocks to subscribe to.
	pool   *clients.ClientPool // Client pool for Ethereum blockchain interaction.
	state  *state.State        // State
	status Status              // Current status of the subscription.
	done   chan struct{}
	mu     sync.RWMutex               // Mutex to protect access to the status field.
	sub    ethereum.Subscription      // Ethereum subscription object (unused in the archive context but available for future use).
	hooks  map[HookType][]BlockHookFn // Hooks to be executed on each block.
}

// NewArchiveBlock initializes a new subscription for Ethereum archive blocks
// using the provided context, client pool, subscription options, and hooks.
// It returns an initialized ArchiveBlock object or an error if initialization fails.
func NewArchiveBlock(ctx context.Context, pool *clients.ClientPool, sm *state.State, opts *options.Subscriber, hooks map[HookType][]BlockHookFn) (*ArchiveBlock, error) {
	if err := opts.Validate(); err != nil {
		return nil, fmt.Errorf(
			"faulure to validate archive block subscriber options: %w", err,
		)
	}

	return &ArchiveBlock{
		ctx:   ctx,
		opts:  opts,
		pool:  pool,
		hooks: hooks,
		done:  make(chan struct{}),
		mu:    sync.RWMutex{},
		state: sm,
	}, nil
}

// Start begins the subscription process for the specified range of archive blocks.
// It iterates over each block in the range, retrieves it, and executes the registered hooks.
// Logs are generated to indicate the process status and any errors encountered.
func (b *ArchiveBlock) Start() error {
	zap.L().Info("Starting up block subscriber...", zap.Any("direction", ArchiveBlockSubscriber), zap.Bool("enabled", b.opts.Enabled), zap.Int("start_block_number", b.opts.StartBlockNumber), zap.Int("end_block_number", b.opts.EndBlockNumber))

	if !b.opts.Enabled {
		return nil // Subscription is disabled; do nothing.
	}

	network, err := utils.GetNetworkFromString(b.opts.Network)
	if err != nil {
		return fmt.Errorf(
			"provided subscriber network is not supported: %s", b.opts.Network,
		)
	}

	if err := b.state.Set(b.ctx, state.ArchiveStartBlockNumber, big.NewInt(int64(b.opts.StartBlockNumber))); err != nil {
		return fmt.Errorf(
			"failure to set start block number archive state: %w",
			err,
		)
	}

	if err := b.state.Set(b.ctx, state.ArchiveEndBlockNumber, big.NewInt(int64(b.opts.EndBlockNumber))); err != nil {
		return fmt.Errorf(
			"failure to set end block number archive state: %w",
			err,
		)
	}

	select {
	case <-b.ctx.Done():
		return nil
	case <-b.done:
		return nil
	default:
		client := b.pool.GetClientByGroup(network.String())
		if client == nil {
			return fmt.Errorf("failure to get '%s' client from client pool", network.String())
		}

		b.status = StatusActive
		defer func() { b.status = StatusNotActive }() // Ensure status is updated when the operation completes.

		startBlockNumber := b.opts.StartBlockNumber

		// In case we want to resume from latest known good (downloaded) block
		if b.opts.Resumption {
			if b.state.Descriptor().LatestInspectedArchiveBlock != nil {
				if int(b.state.Descriptor().LatestInspectedArchiveBlock.Int64()) >= startBlockNumber {
					startBlockNumber = int(b.state.Descriptor().LatestInspectedArchiveBlock.Int64())
				}
			}
		}

		var mu sync.Mutex // Local mutex for synchronizing block processing.
		for i := startBlockNumber; i <= b.opts.EndBlockNumber; i++ {
			mu.Lock()
			block, err := client.BlockByNumber(b.ctx, big.NewInt(int64(i)))
			if err != nil {
				zap.L().Error("Failed to get block by number", zap.Error(err), zap.Any("direction", ArchiveBlockSubscriber), zap.Int("block_number", i))
				mu.Unlock()
				continue
			}

			// Execute post hooks on the block.
			for _, hook := range b.hooks[PostHook] {
				block, err := hook(block)
				if err != nil {
					zap.L().Error("failure to process post block hook", zap.Error(err), zap.Any("direction", ArchiveBlockSubscriber), zap.Uint64("header_number", block.NumberU64()), zap.String("header_hash", block.Hash().String()))
					continue
				}
			}
			mu.Unlock()
		}
	}

	return nil
}

// Stop terminates the archive block subscription and performs any necessary cleanup.
func (b *ArchiveBlock) Stop() error {
	zap.L().Info("Stopping block subscriber...")
	close(b.done)
	return nil
}

// Status returns the current status of the archive block subscription.
func (b *ArchiveBlock) Status() Status {
	b.mu.RLock()
	defer b.mu.RUnlock()
	return b.status
}
