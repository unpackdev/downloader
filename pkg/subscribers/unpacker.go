package subscribers

import (
	"context"
	"fmt"
	"github.com/nats-io/nats.go"
	"github.com/unpackdev/inspector/pkg/events"
	"github.com/unpackdev/inspector/pkg/options"
	"github.com/unpackdev/inspector/pkg/state"
	"github.com/unpackdev/solgo/clients"
	"go.uber.org/zap"
	"sync"
)

// UnpackerSubscriber defines the subscriber type for new head blocks.
var UnpackerSubscriber SubscriberType = "unpacker"

// Unpacker ...
type Unpacker struct {
	ctx    context.Context               // Context for managing the lifecycle of the subscription.
	opts   *options.Subscriber           // Subscription options.
	pool   *clients.ClientPool           // Pool of Ethereum clients for blockchain interaction.
	state  *state.State                  // State to keep track of the current blockchain state
	status Status                        // Current status of the subscription.
	nats   *nats.Conn                    // Connection to the NATS server
	mu     sync.RWMutex                  // Mutex to protect access to the status field.
	hooks  map[HookType][]UnpackerHookFn // Registered hooks to be executed on new unpacker requests.
}

func NewUnpacker(ctx context.Context, pool *clients.ClientPool, sm *state.State, ncConn *nats.Conn, opts *options.Subscriber, hooks map[HookType][]UnpackerHookFn) (*Unpacker, error) {
	if err := opts.Validate(); err != nil {
		return nil, fmt.Errorf(
			"failure to validate unpack subscriber options: %w", err,
		)
	}
	return &Unpacker{
		ctx:   ctx,
		opts:  opts,
		pool:  pool,
		hooks: hooks,
		mu:    sync.RWMutex{},
		state: sm,
		nats:  ncConn,
	}, nil
}

// Start begins listening for unpacking requests on the NATS subject specified in the options.
func (b *Unpacker) Start() error {
	zap.L().Info("Starting up unpacker subscriber...", zap.Bool("enabled", b.opts.Enabled), zap.String("subject", b.opts.SubjectName))

	if !b.opts.Enabled {
		return nil // Subscription is disabled; do nothing.
	}

	// Subscribe to the NATS subject specified in the options.
	sub, err := b.nats.Subscribe(b.opts.SubjectName, func(msg *nats.Msg) {
		// This is a placeholder for your message handling logic.
		// You'll likely need to unmarshal the message and then process it.
		zap.L().Info("Received message", zap.ByteString("data", msg.Data))

		event, err := events.UnmarshalUnpack(msg.Data)
		if err != nil {
			zap.L().Error("failure to unmarshal unpacker event data",
				zap.Error(err),
				zap.Any("subscriber", UnpackerSubscriber),
				zap.Any("event_data", msg.Data),
			)
			return
		}

		// Execute post hooks on the block.
		for _, hook := range b.hooks[PostHook] {
			if err := hook(event); err != nil {
				zap.L().Error("failure to process unpacker hook",
					zap.Error(err),
					zap.Any("subscriber", UnpackerSubscriber),
					zap.Any("event_data", msg.Data),
				)
				continue
			}
		}
	})

	if err != nil {
		return fmt.Errorf("failure subscribing to subject %s: %w", b.opts.SubjectName, err)
	}

	// Ensure the subscription is properly unsubscribed when the context is done.
	<-b.ctx.Done()
	if err := sub.Unsubscribe(); err != nil {
		return fmt.Errorf(
			"failure to unsubscribe from the subject '%s': %w", b.opts.SubjectName, err,
		)
	}

	return nil
}

// Stop terminates the unpacker subscription and performs any necessary cleanup.
func (b *Unpacker) Stop() error {
	zap.L().Info("Stopping unpacker subscriber...")
	return nil // Implement cleanup and subscription termination logic.
}

// Status returns the current status of the unpacker subscription.
func (b *Unpacker) Status() Status {
	b.mu.RLock()
	defer b.mu.RUnlock()
	return b.status
}
