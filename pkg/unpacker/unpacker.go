package unpacker

import (
	"context"
	"fmt"

	"github.com/0x19/solc-switch"
	"github.com/nats-io/nats.go"
	"github.com/unpackdev/solgo/bindings"
	"github.com/unpackdev/solgo/clients"
	"github.com/unpackdev/solgo/metadata"
	"github.com/unpackdev/solgo/providers/bitquery"
	"github.com/unpackdev/solgo/providers/etherscan"
	"github.com/unpackdev/solgo/simulator"
	"github.com/unpackdev/solgo/storage"
	"github.com/unpackdev/trader/pkg/cache"
	"github.com/unpackdev/trader/pkg/db"
	"github.com/unpackdev/trader/pkg/downloader"
	"github.com/unpackdev/trader/pkg/websockets"
)

type Option func(*Unpacker) error

type Unpacker struct {
	ctx         context.Context
	clientsPool *clients.ClientPool
	cacheClient *cache.Redis
	bqp         *bitquery.BitQueryProvider
	etherscan   *etherscan.EtherScanProvider
	wsPool      *websockets.ClientPool
	compiler    *solc.Solc
	bindManager *bindings.Manager
	dbAdapter   *db.Adapter
	nsConn      *nats.Conn
	jsCtx       nats.JetStreamContext
	sim         *simulator.Simulator
	stor        *storage.Storage
	provider    metadata.Provider
	downloader  *downloader.Downloader
}

func NewUnpacker(ctx context.Context, clientsPool *clients.ClientPool, cacheClient *cache.Redis, opts ...Option) (*Unpacker, error) {
	if clientsPool == nil {
		return nil, fmt.Errorf("clients pool is not set")
	}

	if cacheClient == nil {
		return nil, fmt.Errorf("cache client is not set")
	}

	u := &Unpacker{
		ctx:         ctx,
		clientsPool: clientsPool,
		cacheClient: cacheClient,
	}

	for _, opt := range opts {
		err := opt(u)
		if err != nil {
			return nil, err
		}
	}

	return u, nil
}

// WithWebSocketsPool sets the WebSocket client pool
func WithWebSocketsPool(wsPool *websockets.ClientPool) Option {
	return func(u *Unpacker) error {
		if wsPool == nil {
			return fmt.Errorf("websockets client pool is nil")
		}
		u.wsPool = wsPool
		return nil
	}
}

// WithCompiler sets the Solidity compiler
func WithCompiler(compiler *solc.Solc) Option {
	return func(u *Unpacker) error {
		if compiler == nil {
			return fmt.Errorf("compiler is nil")
		}
		u.compiler = compiler
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

// WithDatabaseAdapter sets the database adapter
func WithDatabaseAdapter(dbAdapter *db.Adapter) Option {
	return func(u *Unpacker) error {
		if dbAdapter == nil {
			return fmt.Errorf("database adapter is nil")
		}
		u.dbAdapter = dbAdapter
		return nil
	}
}

// WithNATSConnection sets the NATS connection
func WithNATSConnection(nsConn *nats.Conn) Option {
	return func(u *Unpacker) error {
		if nsConn == nil {
			return fmt.Errorf("NATS connection is nil")
		}
		u.nsConn = nsConn
		return nil
	}
}

// WithJetStreamContext sets the NATS JetStream context
func WithJetStreamContext(jsCtx nats.JetStreamContext) Option {
	return func(u *Unpacker) error {
		// Note: Add validation if necessary
		u.jsCtx = jsCtx
		return nil
	}
}

// WithSimulator sets the blockchain simulator
func WithSimulator(sim *simulator.Simulator) Option {
	return func(u *Unpacker) error {
		if sim == nil {
			return fmt.Errorf("simulator is nil")
		}
		u.sim = sim
		return nil
	}
}

// WithStorage sets the storage
func WithStorage(stor *storage.Storage) Option {
	return func(u *Unpacker) error {
		if stor == nil {
			return fmt.Errorf("storage is nil")
		}
		u.stor = stor
		return nil
	}
}

// WithMetadataProvider sets the metadata provider
func WithMetadataProvider(provider metadata.Provider) Option {
	return func(u *Unpacker) error {
		// Note: Add validation if necessary
		u.provider = provider
		return nil
	}
}

func WithBitQueryProvider(bqp *bitquery.BitQueryProvider) Option {
	return func(u *Unpacker) error {
		if bqp == nil {
			return fmt.Errorf("bitquery provider is nil")
		}
		u.bqp = bqp
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

func WithDownloader(downloader *downloader.Downloader) Option {
	return func(u *Unpacker) error {
		if downloader == nil {
			return fmt.Errorf("downloader is nil")
		}
		u.downloader = downloader
		return nil
	}
}
