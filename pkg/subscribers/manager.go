package subscribers

import (
	"context"
	"fmt"
	"golang.org/x/sync/errgroup"
	"sync"
)

type Manager struct {
	ctx  context.Context
	subs map[SubscriberType]Subscriber
	mu   sync.RWMutex
}

// TODO: Add validation...
func NewManager(ctx context.Context) (*Manager, error) {
	return &Manager{
		ctx:  ctx,
		subs: make(map[SubscriberType]Subscriber),
		mu:   sync.RWMutex{},
	}, nil
}

func (m *Manager) Exists(name SubscriberType) bool {
	m.mu.RLock()
	defer m.mu.RUnlock()
	_, ok := m.subs[name]
	return ok
}

func (m *Manager) Register(name SubscriberType, sub Subscriber) error {
	if m.Exists(name) {
		return fmt.Errorf(
			"rejecting subscriber '%s' registration as it already exists",
			name,
		)
	}

	m.mu.Lock()
	m.subs[name] = sub
	m.mu.Unlock()
	return nil
}

// UnRegister removes a subscriber from the manager
func (m *Manager) UnRegister(name SubscriberType) error {
	if m.Exists(name) {
		return fmt.Errorf(
			"rejecting subscriber '%s' removal as it does not exist",
			name,
		)
	}

	m.mu.Lock()
	defer m.mu.Unlock()
	delete(m.subs, name)
	return nil
}

// Get retrieves a subscriber by name
func (m *Manager) Get(name SubscriberType) (Subscriber, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	sub, ok := m.subs[name]
	if !ok {
		return nil, fmt.Errorf("subscriber '%s' not found", name)
	}
	return sub, nil
}

func (m *Manager) List() map[SubscriberType]Subscriber {
	return m.subs
}

func (m *Manager) Subscribe(names ...SubscriberType) error {
	g, ctx := errgroup.WithContext(m.ctx)

	// Define a helper function to start a subscriber
	startSubscriber := func(sub Subscriber) error {
		select {
		case <-ctx.Done():
			return ctx.Err()
		default:
			return sub.Start()
		}
	}

	if len(names) > 0 {
		// Start only the subscribers with the provided names
		for _, name := range names {
			sub, ok := m.subs[name]
			if ok {
				g.Go(func() error {
					return startSubscriber(sub)
				})
			}
		}
	} else {
		// Start all subscribers
		for _, sub := range m.subs {
			g.Go(func() error {
				return startSubscriber(sub)
			})
		}
	}

	// Wait for all goroutines to complete
	return g.Wait()
}

func (m *Manager) Close() error {
	g, ctx := errgroup.WithContext(m.ctx)

	for _, sub := range m.subs {
		if sub.Status() == StatusActive {
			g.Go(func() error {
				return sub.Stop()
			})
		}
	}

	select {
	case <-ctx.Done():
		return nil
	}
}
