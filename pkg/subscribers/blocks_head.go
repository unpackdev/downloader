package subscribers

import (
	"context"
	"fmt"
	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/unpackdev/inspector/pkg/options"
	"github.com/unpackdev/inspector/pkg/state"
	"github.com/unpackdev/solgo/clients"
	"github.com/unpackdev/solgo/utils"
	"go.uber.org/zap"
	"sync"
	"time"
)

// HeadBlockSubscriber defines the subscriber type for new head blocks.
var HeadBlockSubscriber SubscriberType = "head"

// Block represents a subscription to blockchain head blocks, encapsulating
// the logic for starting, managing, and executing hooks on new blocks.
type Block struct {
	ctx    context.Context            // Context for managing the lifecycle of the subscription.
	opts   *options.Subscriber        // Subscription options.
	pool   *clients.ClientPool        // Pool of Ethereum clients for blockchain interaction.
	state  *state.State               // State to keep track of the current blockchain state
	status Status                     // Current status of the subscription.
	mu     sync.RWMutex               // Mutex to protect access to the status field.
	sub    ethereum.Subscription      // Ethereum's subscription object for new head blocks.
	hooks  map[HookType][]BlockHookFn // Registered hooks to be executed on new blocks.
}

// NewHeadBlock initializes a new head block subscription using the provided context,
// client pool, subscription options, and hooks. It returns an initialized Block object
// or an error if initialization fails.
func NewHeadBlock(ctx context.Context, pool *clients.ClientPool, sm *state.State, opts *options.Subscriber, hooks map[HookType][]BlockHookFn) (*Block, error) {
	if err := opts.Validate(); err != nil {
		return nil, fmt.Errorf(
			"faulure to validate head block subscriber options: %w", err,
		)
	}
	return &Block{
		ctx:   ctx,
		opts:  opts,
		pool:  pool,
		hooks: hooks,
		mu:    sync.RWMutex{},
		state: sm,
	}, nil
}

// Start begins the subscription to new head blocks. It connects to an Ethereum client,
// subscribes to new head blocks, and executes registered hooks on each new block.
// Logs information about subscription status and errors encountered during block
// retrieval or hook execution.
func (b *Block) Start() error {
	zap.L().Info("Starting up block subscriber...", zap.Any("direction", HeadBlockSubscriber), zap.Bool("enabled", b.opts.Enabled))

	if !b.opts.Enabled {
		return nil // Subscription is disabled; do nothing.
	}

	network, err := utils.GetNetworkFromString(b.opts.Network)
	if err != nil {
		return fmt.Errorf(
			"provided subscriber network is not supported: %s", b.opts.Network,
		)
	}

	client := b.pool.GetClientByGroup(network.String())
	if client == nil {
		return fmt.Errorf("failure to get '%s' client from client pool", network.String())
	}

	chCtx, chCancel := context.WithTimeout(b.ctx, 10*time.Second)
	defer chCancel()

	currentHead, err := client.BlockByNumber(chCtx, nil)
	if err != nil {
		return fmt.Errorf(
			"failure to fetch current head from the client: %w",
			err,
		)
	}

	if err := b.state.Set(chCtx, state.CurrentBlockHead, currentHead.Header().Number); err != nil {
		zap.L().Error(
			"failure to set current block head state",
			zap.Error(err),
			zap.Any("direction", HeadBlockSubscriber),
			zap.Uint64("header_number", currentHead.NumberU64()),
			zap.String("header_hash", currentHead.Hash().String()),
		)
		return fmt.Errorf(
			"failure to set current block head state: %w",
			err,
		)
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
			return nil // Subscription stopped as context is done.
		case err := <-sub.Err():
			return err // Handle subscription errors.
		case header := <-headCh:
			// Process new head block.
			block, err := client.BlockByNumber(b.ctx, header.Number)
			if err != nil {
				zap.L().Error("Failed to get block by hash", zap.Error(err), zap.Any("direction", HeadBlockSubscriber), zap.Uint64("header_number", header.Number.Uint64()), zap.String("header_hash", header.Hash().String()))
				continue
			}

			ctx, cancel := context.WithTimeout(b.ctx, 10*time.Second)
			if err := b.state.Set(ctx, state.CurrentBlockHead, block.Header().Number); err != nil {
				cancel()
				zap.L().Error(
					"failure to set current block head state",
					zap.Error(err),
					zap.Any("direction", HeadBlockSubscriber),
					zap.Uint64("header_number", block.NumberU64()),
					zap.String("header_hash", block.Hash().String()),
				)
				continue
			}

			// Cancel the context for the state... We cannot use defer...
			cancel()

			fmt.Println("NEW HEAD RECEIVED....", block.NumberU64())

			// Execute post hooks on the block.
			for _, hook := range b.hooks[PostHook] {
				block, err := hook(block)
				if err != nil {
					zap.L().Error("failure to process post block hook",
						zap.Error(err),
						zap.Any("direction", HeadBlockSubscriber),
						zap.Uint64("header_number", block.NumberU64()),
						zap.String("header_hash", block.Hash().String()),
					)
					continue
				}
			}
		}
	}
}

// Stop terminates the block subscription and performs any necessary cleanup.
func (b *Block) Stop() error {
	zap.L().Info("Stopping block subscriber...")
	return nil // Implement cleanup and subscription termination logic.
}

// Status returns the current status of the block subscription.
func (b *Block) Status() Status {
	b.mu.RLock()
	defer b.mu.RUnlock()
	return b.status
}
