package unpacker

import (
	"context"
	"fmt"
	"github.com/nats-io/nats.go"
	"github.com/unpackdev/inspector/pkg/storage"
	"github.com/unpackdev/solgo/bindings"
	"github.com/unpackdev/solgo/clients"
	"github.com/unpackdev/solgo/providers/etherscan"
)

type Option func(*Unpacker) error

type Unpacker struct {
	ctx         context.Context
	pool        *clients.ClientPool
	etherscan   *etherscan.EtherScanProvider
	nats        *nats.Conn
	js          nats.JetStreamContext
	storage     *storage.Storage
	bindManager *bindings.Manager
}

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

// WithPool sets the client pool
func WithPool(pool *clients.ClientPool) Option {
	return func(u *Unpacker) error {
		if pool == nil {
			return fmt.Errorf("client pool is nil")
		}
		u.pool = pool
		return nil
	}
}

// WithNats sets the NATS connection
func WithNats(nsConn *nats.Conn) Option {
	return func(u *Unpacker) error {
		if nsConn == nil {
			return fmt.Errorf("NATS connection is nil")
		}
		u.nats = nsConn
		return nil
	}
}

// WithBindingsManager sets the bindings manager
func WithBindingsManager(bindManager *bindings.Manager) Option {
	return func(u *Unpacker) error {
		if bindManager == nil {
			return fmt.Errorf("bindings manager is nil")
		}
		u.bindManager = bindManager
		return nil
	}
}

// WithJetStreamContext sets the NATS JetStream context
func WithJetStreamContext(jsCtx nats.JetStreamContext) Option {
	return func(u *Unpacker) error {
		u.js = jsCtx
		return nil
	}
}

func WithEtherScanProvider(etherscan *etherscan.EtherScanProvider) Option {
	return func(u *Unpacker) error {
		if etherscan == nil {
			return fmt.Errorf("etherscan provider is nil")
		}
		u.etherscan = etherscan
		return nil
	}
}

func WithStorage(stor *storage.Storage) Option {
	return func(u *Unpacker) error {
		if stor == nil {
			return fmt.Errorf("storage is nil")
		}
		u.storage = stor
		return nil
	}
}
