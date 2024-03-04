package graph

import (
	"context"
	"time"

	"github.com/redis/go-redis/v9"
)

type Cache struct {
	ctx    context.Context
	client redis.UniversalClient
	ttl    time.Duration
}

const apqPrefix = "unpack:apq:"

func NewCache(ctx context.Context, client *redis.Client, ttl time.Duration) (*Cache, error) {
	return &Cache{ctx: ctx, client: client, ttl: ttl}, nil
}

func (c *Cache) Add(ctx context.Context, key string, value interface{}) {
	c.client.Set(ctx, apqPrefix+key, value, c.ttl)
}

func (c *Cache) Get(ctx context.Context, key string) (interface{}, bool) {
	s, err := c.client.Get(ctx, apqPrefix+key).Result()
	if err != nil {
		return struct{}{}, false
	}
	return s, true
}
