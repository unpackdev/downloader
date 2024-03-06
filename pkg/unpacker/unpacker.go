package unpacker

import (
	"context"
	"errors"
	"fmt"
	"github.com/nats-io/nats.go"
	"github.com/unpackdev/inspector/pkg/db"
	"github.com/unpackdev/inspector/pkg/state"
	"github.com/unpackdev/solgo/bindings"
	"github.com/unpackdev/solgo/clients"
	"github.com/unpackdev/solgo/providers/etherscan"
)

// Option defines a functional option for configuring the Unpacker.
type Option func(*Unpacker) error

// Unpacker orchestrates blockchain data extraction and processing. It leverages a client pool for blockchain interaction,
// etherscan for blockchain data, NATS for messaging, a bindings manager for smart contract interaction,
// and a database for persistent storage.
type Unpacker struct {
	ctx         context.Context              // Context for cancellation and deadline control.
	pool        *clients.ClientPool          // Pool of blockchain clients for efficient resource management.
	etherscan   *etherscan.EtherScanProvider // Provider for Ethereum blockchain data.
	nats        *nats.Conn                   // NATS connection for messaging.
	js          nats.JetStreamContext        // JetStream context for advanced NATS messaging features.
	db          *db.Db                       // Database for persistent storage.
	bindManager *bindings.Manager            // Manager for smart contract bindings.
	state       *state.State                 // State manager for synchronizer state tracking.
}

// NewUnpacker creates a new Unpacker instance with optional configurations.
// It initializes the Unpacker with a context and applies any provided configuration options.
func NewUnpacker(ctx context.Context, opts ...Option) (*Unpacker, error) {
	u := &Unpacker{ctx: ctx}

	for _, opt := range opts {
		err := opt(u)
		if err != nil {
			return nil, err
		}
	}

	return u, nil
}

// WithPool configures the Unpacker with a specific client pool for blockchain interactions.
func WithPool(pool *clients.ClientPool) Option {
	return func(u *Unpacker) error {
		if pool == nil {
			return fmt.Errorf("client pool is nil")
		}
		u.pool = pool
		return nil
	}
}

// WithNats configures the Unpacker with a specific NATS connection for messaging.
func WithNats(nsConn *nats.Conn) Option {
	return func(u *Unpacker) error {
		if nsConn == nil {
			return fmt.Errorf("NATS connection is nil")
		}
		u.nats = nsConn
		return nil
	}
}

// WithBindingsManager configures the Unpacker with a specific bindings manager for smart contract interaction.
func WithBindingsManager(bindManager *bindings.Manager) Option {
	return func(u *Unpacker) error {
		if bindManager == nil {
			return fmt.Errorf("bindings manager is nil")
		}
		u.bindManager = bindManager
		return nil
	}
}

// WithJetStreamContext configures the Unpacker with a specific NATS JetStream context for advanced messaging capabilities.
func WithJetStreamContext(jsCtx nats.JetStreamContext) Option {
	return func(u *Unpacker) error {
		u.js = jsCtx
		return nil
	}
}

// WithEtherScanProvider configures the Unpacker with a specific EtherScan provider for Ethereum blockchain data.
func WithEtherScanProvider(etherscan *etherscan.EtherScanProvider) Option {
	return func(u *Unpacker) error {
		if etherscan == nil {
			return fmt.Errorf("etherscan provider is nil")
		}
		u.etherscan = etherscan
		return nil
	}
}

// WithDb configures the Unpacker with a specific database for persistent storage.
func WithDb(d *db.Db) Option {
	return func(u *Unpacker) error {
		if d == nil {
			return fmt.Errorf("database is nil")
		}
		u.db = d
		return nil
	}
}

// WithStateManager configures the Unpacker with a specific state manager for application state tracking.
func WithStateManager(sm *state.State) Option {
	return func(u *Unpacker) error {
		if sm == nil {
			return errors.New("state manager cannot be nil")
		}
		u.state = sm
		return nil
	}
}
