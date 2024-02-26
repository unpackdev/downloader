package syncer

import (
	"github.com/unpackdev/downloader/pkg/options"
	"github.com/unpackdev/downloader/pkg/subscribers"
	"github.com/unpackdev/solgo/utils"
	"go.uber.org/zap"
)

var (
	subsMap = map[subscribers.SubscriberType]func(srv *Service, network utils.Network, networkId utils.NetworkID) (subscribers.Subscriber, error){
		subscribers.HeadBlockSubscriber: func(srv *Service, network utils.Network, networkId utils.NetworkID) (subscribers.Subscriber, error) {
			hooks := make(map[subscribers.HookType][]subscribers.BlockHookFn)
			hooks[subscribers.PostHook] = []subscribers.BlockHookFn{
				BlockHeadInterceptor(srv, network, networkId, HeadSyncDirection),
			}

			// Have to use .String() - otherwise cycle import...
			opts, err := options.G().Syncer.GetByType(subscribers.HeadBlockSubscriber.String())
			if err != nil {
				return nil, err
			}

			bs, err := subscribers.NewHeadBlock(srv.ctx, srv.pool, opts, hooks)
			if err != nil {
				return nil, err
			}

			return bs, nil
		},
		subscribers.ArchiveBlockSubscriber: func(srv *Service, network utils.Network, networkId utils.NetworkID) (subscribers.Subscriber, error) {
			hooks := make(map[subscribers.HookType][]subscribers.BlockHookFn)
			hooks[subscribers.PostHook] = []subscribers.BlockHookFn{
				BlockHeadInterceptor(srv, network, networkId, ArchiveSyncDirection),
			}

			// Have to use .String() - otherwise cycle import...
			opts, err := options.G().Syncer.GetByType(subscribers.ArchiveBlockSubscriber.String())
			if err != nil {
				return nil, err
			}

			bs, err := subscribers.NewArchiveBlock(srv.ctx, srv.pool, opts, hooks)
			if err != nil {
				return nil, err
			}

			return bs, nil
		},
	}
)

// InjectSubscribers will look into map of the subscribers and attempt to register them against subscriber
// manager. In case of any issues, it will sequentially fail. It's deliberate to fail on sequence instead of spawning
// goroutines and returning back errors.
func InjectSubscribers(service *Service, network utils.Network, networkId utils.NetworkID) error {
	for name, subFn := range subsMap {
		zap.L().Debug(
			"Registering new blockchain state subscriber",
			zap.String("name", name.String()),
			zap.Any("network", network),
			zap.Any("network_id", networkId),
		)

		sub, err := subFn(service, network, networkId)
		if err != nil {
			return err
		}

		if err := service.subs.Register(name, sub); err != nil {
			return err
		}
	}

	return nil
}
