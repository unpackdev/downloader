package syncer

import (
	"context"
	"fmt"
	"github.com/nats-io/nats.go"
	"github.com/unpackdev/downloader/pkg/options"
	"github.com/unpackdev/solgo/clients"
	"github.com/unpackdev/solgo/utils"
	"go.uber.org/zap"
	"golang.org/x/sync/errgroup"
)

type Service struct {
	ctx      context.Context
	pool     *clients.ClientPool
	natsConn *nats.Conn
}

func (s *Service) Start(network utils.Network, networkId utils.NetworkID) error {
	zap.L().Info(
		"Starting up syncer service",
		zap.Any("network", network),
		zap.Any("network_id", networkId),
	)

	g, ctx := errgroup.WithContext(s.ctx)

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
	clientsPool, err := clients.NewClientPool(ctx, options.G().Options)
	if err != nil {
		return nil, fmt.Errorf("failure to create clients pool: %w", err)
	}

	nsConn, err := nats.Connect(options.G().Nats.Addr)
	if err != nil {
		return nil, fmt.Errorf("failure to connect to the nats server: %w", err)
	}

	toReturn := &Service{
		ctx:      ctx,
		pool:     clientsPool,
		natsConn: nsConn,
	}

	return toReturn, nil
}
