package query

import (
	"context"
	"fmt"
	"github.com/nats-io/nats.go"
	"github.com/unpackdev/inspector/pkg/cache"
	"github.com/unpackdev/inspector/pkg/db"
	"github.com/unpackdev/inspector/pkg/options"
	"github.com/unpackdev/inspector/pkg/storage"
	"github.com/unpackdev/inspector/pkg/subscribers"
	"github.com/unpackdev/inspector/pkg/unpacker"
	"github.com/unpackdev/solgo/bindings"
	"github.com/unpackdev/solgo/clients"
	"github.com/unpackdev/solgo/providers/etherscan"
	"go.uber.org/zap"
	"golang.org/x/sync/errgroup"
)

type Service struct {
	ctx         context.Context
	pool        *clients.ClientPool
	nats        *nats.Conn
	db          *db.Db
	subs        *subscribers.Manager
	storage     *storage.Storage
	unpacker    *unpacker.Unpacker
	etherscan   *etherscan.EtherScanProvider
	bindManager *bindings.Manager
	cache       *cache.Redis
}

func (s *Service) Start() error {
	zap.L().Info(
		"Starting up query service",
	)

	g, ctx := errgroup.WithContext(s.ctx)

	g.Go(func() error {
		return s.serveGraphQL()
	})

	// Wait for goroutines to finish....
	if err := g.Wait(); err != nil {
		return err
	}

	select {
	case <-ctx.Done():
		zap.L().Info(
			"Stopped query service",
		)
		return nil
	}
}

func NewService(ctx context.Context) (*Service, error) {
	opts := options.G()

	if err := opts.Validate(); err != nil {
		return nil, fmt.Errorf("failure to validate service options: %w", err)
	}

	clientsPool, err := clients.NewClientPool(ctx, opts.Options)
	if err != nil {
		return nil, fmt.Errorf("failure to create clients pool: %w", err)
	}

	nsConn, err := nats.Connect(opts.Nats.Addr)
	if err != nil {
		return nil, fmt.Errorf("failure to connect to the nats server: %w", err)
	}

	// Note that there can be only one application accessing specific badgerdb database at the time...
	// It's foobar strategy but heck we'll need to build RPC endpoints on top of it.

	dDb, err := db.NewDB(ctx, opts)
	if err != nil {
		return nil, fmt.Errorf("failure to open up the sqlite database: %w", err)
	}

	subManager, err := subscribers.NewManager(ctx)
	if err != nil {
		return nil, fmt.Errorf("failure to create new subscriber manager: %w", err)
	}

	storageManager, err := storage.New(ctx, opts.Storage, dDb)
	if err != nil {
		return nil, fmt.Errorf("failure to initiate new downloader storage: %w", err)
	}

	bindManager, err := bindings.NewManager(ctx, clientsPool)
	if err != nil {
		return nil, fmt.Errorf("failure to create bindings manager: %w", err)
	}

	cacheClient, err := cache.New(ctx, opts.Cache)
	if err != nil {
		return nil, fmt.Errorf("failure to create redis client: %w", err)
	}

	etherscanProvider, err := etherscan.NewEtherScanProvider(ctx, cacheClient.GetClient(), opts.Etherscan)
	if err != nil {
		return nil, fmt.Errorf("failure to create new etherscan provider: %w", err)
	}

	unpackerOpts := []unpacker.Option{
		unpacker.WithNats(nsConn),
		unpacker.WithPool(clientsPool),
		unpacker.WithStorage(storageManager),
		unpacker.WithBindingsManager(bindManager),
		unpacker.WithEtherScanProvider(etherscanProvider),
	}

	unp, err := unpacker.NewUnpacker(ctx, unpackerOpts...)
	if err != nil {
		return nil, fmt.Errorf("failure to initiate new unpacker instance: %w", err)
	}

	toReturn := &Service{
		ctx:         ctx,
		pool:        clientsPool,
		nats:        nsConn,
		db:          dDb,
		subs:        subManager,
		storage:     storageManager,
		unpacker:    unp,
		bindManager: bindManager,
		cache:       cacheClient,
		etherscan:   etherscanProvider,
	}

	return toReturn, nil
}
