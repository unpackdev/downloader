package syncer

import (
	"context"
	"fmt"
	"github.com/nats-io/nats.go"
	"github.com/unpackdev/downloader/pkg/db"
	"github.com/unpackdev/downloader/pkg/options"
	"github.com/unpackdev/downloader/pkg/storage"
	"github.com/unpackdev/downloader/pkg/subscribers"
	"github.com/unpackdev/downloader/pkg/unpacker"
	"github.com/unpackdev/solgo/clients"
	"github.com/unpackdev/solgo/providers/etherscan"
	"github.com/unpackdev/solgo/utils"
	"go.uber.org/zap"
	"golang.org/x/sync/errgroup"
)

type Service struct {
	ctx       context.Context
	pool      *clients.ClientPool
	nats      *nats.Conn
	db        *db.BadgerDB
	subs      *subscribers.Manager
	storage   *storage.Storage
	unpacker  *unpacker.Unpacker
	etherscan *etherscan.EtherScanProvider
}

func (s *Service) Start(network utils.Network, networkId utils.NetworkID) error {
	zap.L().Info(
		"Starting up syncer service",
		zap.Any("network", network),
		zap.Any("network_id", networkId),
	)

	if err := InjectSubscribers(s, network, networkId); err != nil {
		return fmt.Errorf("failure to inject subscribers: %w", err)
	}

	g, ctx := errgroup.WithContext(s.ctx)

	g.Go(func() error {
		return s.subs.Subscribe()
	})

	// Wait for goroutines to finish....
	if err := g.Wait(); err != nil {
		return err
	}

	select {
	case <-ctx.Done():
		zap.L().Info(
			"Flattening badger db database...",
			zap.Any("network", network),
			zap.Any("network_id", networkId),
		)

		if err := s.db.DB().Flatten(options.G().Db.FlattenWorkers); err != nil {
			zap.L().Error(
				"failure to flatten badger db database on service shutdown",
				zap.Error(err),
				zap.Any("network", network),
				zap.Any("network_id", networkId),
			)
		}

		zap.L().Info(
			"Stopped syncer service",
			zap.Any("network", network),
			zap.Any("network_id", networkId),
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
	// It's fuubar strategy but heck we'll need to build RPC endpoints on top of it.
	bDb, err := db.NewBadgerDB(db.WithContext(ctx), db.WithDbPath(opts.Storage.DatabasePath))
	if err != nil {
		return nil, fmt.Errorf("failure to open up the badgerdb database: %w", err)
	}

	subManager, err := subscribers.NewManager(ctx)
	if err != nil {
		return nil, fmt.Errorf("failure to create new subscriber manager: %w", err)
	}

	storageManager, err := storage.New(ctx, opts.Storage, bDb)
	if err != nil {
		return nil, fmt.Errorf("failure to initiate new downloader storage: %w", err)
	}

	unpackerOpts := []unpacker.Option{
		unpacker.WithNats(nsConn),
		unpacker.WithPool(clientsPool),
		unpacker.WithStorage(storageManager),
	}

	unp, err := unpacker.NewUnpacker(ctx, unpackerOpts...)
	if err != nil {
		return nil, fmt.Errorf("failure to initiate new unpacker instance: %w", err)
	}

	toReturn := &Service{
		ctx:      ctx,
		pool:     clientsPool,
		nats:     nsConn,
		db:       bDb,
		subs:     subManager,
		storage:  storageManager,
		unpacker: unp,
	}

	return toReturn, nil
}
