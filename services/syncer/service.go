package syncer

import (
	"context"
	"fmt"
	"github.com/nats-io/nats.go"
	"github.com/unpackdev/inspector/pkg/cache"
	"github.com/unpackdev/inspector/pkg/db"
	"github.com/unpackdev/inspector/pkg/options"
	"github.com/unpackdev/inspector/pkg/pprof"
	"github.com/unpackdev/inspector/pkg/state"
	"github.com/unpackdev/inspector/pkg/subscribers"
	"github.com/unpackdev/inspector/pkg/unpacker"
	"github.com/unpackdev/solgo/bindings"
	"github.com/unpackdev/solgo/clients"
	"github.com/unpackdev/solgo/providers/etherscan"
	"github.com/unpackdev/solgo/utils"
	"go.uber.org/zap"
	"golang.org/x/sync/errgroup"
)

type Service struct {
	ctx         context.Context
	pool        *clients.ClientPool
	nats        *nats.Conn
	db          *db.Db
	subs        *subscribers.Manager
	unpacker    *unpacker.Unpacker
	etherscan   *etherscan.EtherScanProvider
	bindManager *bindings.Manager
	cache       *cache.Redis
	pprof       *pprof.Pprof
	state       *state.State
}

func (s *Service) Start(network utils.Network, networkId utils.NetworkID) error {
	zap.L().Info(
		"Starting up syncer service",
		zap.Any("network", network),
		zap.Any("network_id", networkId),
	)

	opts := options.G()

	if err := InjectSubscribers(s, network, networkId); err != nil {
		return fmt.Errorf("failure to inject subscribers: %w", err)
	}

	g, ctx := errgroup.WithContext(s.ctx)

	g.Go(func() error {
		return s.subs.Subscribe()
	})

	if opts.Pprof.Enabled {
		g.Go(func() error {
			return s.pprof.Start()
		})
	}

	g.Go(func() error {
		return s.state.Monitor(ctx)
	})

	// Wait for goroutines to finish....
	if err := g.Wait(); err != nil {
		return err
	}

	select {
	case <-ctx.Done():
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

	dDb, err := db.NewDB(ctx, opts)
	if err != nil {
		return nil, fmt.Errorf("failure to open up the sqlite database: %w", err)
	}

	subManager, err := subscribers.NewManager(ctx)
	if err != nil {
		return nil, fmt.Errorf("failure to create new subscriber manager: %w", err)
	}

	bindManager, err := bindings.NewManager(ctx, clientsPool)
	if err != nil {
		return nil, fmt.Errorf("failure to create bindings manager: %w", err)
	}

	cacheClient, err := cache.New(ctx, opts.Cache)
	if err != nil {
		return nil, fmt.Errorf("failure to create redis client: %w", err)
	}

	stateManager, err := state.New(ctx, cacheClient)
	if err != nil {
		return nil, fmt.Errorf("failure to create state manager: %w", err)
	}

	etherscanProvider, err := etherscan.NewEtherScanProvider(ctx, cacheClient.GetClient(), opts.Etherscan)
	if err != nil {
		return nil, fmt.Errorf("failure to create new etherscan provider: %w", err)
	}

	unpackerOpts := []unpacker.Option{
		unpacker.WithNats(nsConn),
		unpacker.WithPool(clientsPool),
		unpacker.WithDb(dDb),
		unpacker.WithBindingsManager(bindManager),
		unpacker.WithEtherScanProvider(etherscanProvider),
		unpacker.WithStateManager(stateManager),
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
		unpacker:    unp,
		bindManager: bindManager,
		cache:       cacheClient,
		etherscan:   etherscanProvider,
		pprof:       pprof.New(ctx, opts.Pprof),
		state:       stateManager,
	}

	return toReturn, nil
}
