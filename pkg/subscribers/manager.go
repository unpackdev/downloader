package subscribers

import (
	"context"
	"fmt"
	"golang.org/x/sync/errgroup"
	"sync"
)

// Manager coordinates subscribers. It supports adding, removing,
// and notifying subscribers. Operations on Manager are safe for
// concurrent use by multiple goroutines.
type Manager struct {
	ctx  context.Context               // Context controls the lifecycle of all subscribers.
	subs map[SubscriberType]Subscriber // Registered subscribers.
	mu   sync.RWMutex                  // Mutex to ensure concurrent access to subs is safe.
}

// NewManager initializes a new Manager with the provided context.
// The context is used to control the lifecycle of subscribers.
func NewManager(ctx context.Context) (*Manager, error) {
	return &Manager{
		ctx:  ctx,
		subs: make(map[SubscriberType]Subscriber),
		mu:   sync.RWMutex{},
	}, nil
}

// Exists checks if a subscriber of the given name is already registered.
// Returns true if the subscriber exists; otherwise, false.
func (m *Manager) Exists(name SubscriberType) bool {
	m.mu.RLock()
	defer m.mu.RUnlock()
	_, ok := m.subs[name]
	return ok
}

// Register adds a new subscriber under the given name. It returns an error
// if a subscriber with the same name already exists.
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

// UnRegister removes a subscriber identified by name. It returns an error
// if no subscriber by that name exists.
func (m *Manager) UnRegister(name SubscriberType) error {
	if !m.Exists(name) {
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

// Get retrieves a subscriber by name. Returns an error if the subscriber
// does not exist.
func (m *Manager) Get(name SubscriberType) (Subscriber, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	sub, ok := m.subs[name]
	if !ok {
		return nil, fmt.Errorf("subscriber '%s' not found", name)
	}
	return sub, nil
}

// List returns a map of all registered subscribers.
func (m *Manager) List() map[SubscriberType]Subscriber {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return m.subs
}

// Subscribe starts the specified subscribers or all if none are specified.
// It returns an error if any subscriber fails to start.
func (m *Manager) Subscribe(names ...SubscriberType) error {
	g, ctx := errgroup.WithContext(m.ctx)

	startSubscriber := func(sub Subscriber) error {
		select {
		case <-ctx.Done():
			return ctx.Err()
		default:
			return sub.Start()
		}
	}

	for _, name := range names {
		if sub, ok := m.subs[name]; ok {
			g.Go(func() error {
				return startSubscriber(sub)
			})
		}
	}

	if len(names) == 0 {
		for _, sub := range m.subs {
			g.Go(func() error {
				return startSubscriber(sub)
			})
		}
	}

	return g.Wait()
}

// Close stops all active subscribers. It ignores subscribers that are not active.
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
