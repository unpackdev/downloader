package state

import (
	"context"
	"github.com/unpackdev/inspector/pkg/cache"
	"math/big"
)

// State encapsulates the application's state with context awareness and caching capabilities.
// It integrates with a Redis cache to store arbitrary large numbers, commonly used for storing
// and retrieving blockchain-related numeric data.
type State struct {
	ctx   context.Context // Context for cancellation and deadline control.
	cache *cache.Redis    // Redis cache for state persistence.
}

// New initializes a new State instance with a given context and cache.
// It returns a pointer to the created State and any error encountered during its creation.
func New(ctx context.Context, cache *cache.Redis) (*State, error) {
	toReturn := &State{ctx: ctx, cache: cache}
	return toReturn, nil
}

// Set stores a value associated with a key within the state cache.
// It converts the value to a byte slice before writing to the cache for flexibility and efficiency.
func (s *State) Set(ctx context.Context, key Key, value *big.Int) error {
	return s.cache.Write(ctx, key.String(), value.Bytes(), 0)
}

// Get retrieves a value based on a key from the state cache.
// It converts the byte slice response back into a big.Int for usage within the application.
func (s *State) Get(ctx context.Context, key Key) (*big.Int, error) {
	response, err := s.cache.Get(ctx, key.String())
	if err != nil {
		return nil, err
	}

	toReturn := new(big.Int)
	return toReturn.SetBytes(response), nil
}

// Exists checks for the existence of a key within the state cache.
// It returns a boolean indicating the presence of the key and any error encountered.
func (s *State) Exists(ctx context.Context, key Key) (bool, error) {
	return s.cache.Exists(ctx, key.String())
}
