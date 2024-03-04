package state

import (
	"context"
	"github.com/unpackdev/inspector/pkg/cache"
)

type State struct {
	ctx   context.Context
	cache *cache.Redis
}

func New(ctx context.Context, cache *cache.Redis) (*State, error) {
	toReturn := &State{ctx: ctx, cache: cache}
	return toReturn, nil
}
