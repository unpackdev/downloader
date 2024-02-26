package cache

import (
	"context"
	"errors"
	"time"

	"github.com/redis/go-redis/v9"
)

// Redis is a struct that holds the context, options, and the client for a Redis database.
type Redis struct {
	ctx    context.Context
	opts   Options
	client *redis.Client
}

// NewRedis creates a new Redis client with the provided context and options.
// It returns a pointer to the Redis struct and an error if any occurred during the creation of the client.
func NewRedis(ctx context.Context, opts Options) (*Redis, error) {
	r := &Redis{
		ctx:  ctx,
		opts: opts,
		client: redis.NewClient(&redis.Options{
			Addr:            opts.Addr,
			Password:        opts.Password,
			DB:              opts.DB,
			MaxRetries:      opts.MaxRetries,
			MinRetryBackoff: opts.MinRetryBackoff * time.Millisecond,
			MaxRetryBackoff: opts.MaxRetryBackoff * time.Millisecond,
			/* 			DialTimeout:     opts.DialTimeout * time.Millisecond,
			   			ReadTimeout:     opts.ReadTimeout * time.Millisecond,
			   			WriteTimeout:    opts.WriteTimeout * time.Millisecond, */
		}),
	}

	if err := r.ValidateOptions(); err != nil {
		return nil, err
	}

	if resp := r.client.Ping(ctx); resp.Err() != nil {
		return nil, resp.Err()
	}

	return r, nil
}

// ValidateOptions checks the validity of the options used to create a Redis client.
// It returns an error if any of the options are invalid.
func (r *Redis) ValidateOptions() error {
	if r.opts.Addr == "" {
		return errors.New("addr cannot be empty")
	}
	if r.opts.DB < 0 {
		return errors.New("db cannot be negative")
	}
	if r.opts.MaxRetries < 0 {
		return errors.New("max retires cannot be negative")
	}
	if r.opts.MinRetryBackoff < 0 {
		return errors.New("min retry backoff cannot be negative")
	}
	if r.opts.MaxRetryBackoff < 0 {
		return errors.New("max retry backoff cannot be negative")
	}
	return nil
}

// GetClient returns the Redis client.
func (r *Redis) GetClient() *redis.Client {
	return r.client
}

// Get retrieves the value of a key from the Redis database.
// It returns the value as a byte slice and an error if any occurred during the retrieval.
func (r *Redis) Get(ctx context.Context, key string) ([]byte, error) {
	result, err := r.client.Get(ctx, key).Result()
	if err != nil {
		return nil, err
	}
	return []byte(result), nil
}

// Write sets the value of a key in the Redis database with an optional expiration duration.
// It returns an error if any occurred during the write operation.
func (r *Redis) Write(ctx context.Context, key string, value interface{}, expiration time.Duration) error {
	return r.client.Set(ctx, key, value, expiration).Err()
}

// Exists checks if a key exists in the Redis database.
// It returns a boolean indicating the existence of the key and an error if any occurred during the check.
func (r *Redis) Exists(ctx context.Context, key string) (bool, error) {
	resp, err := r.client.Exists(ctx, key).Result()
	if err != nil {
		return false, err
	}
	return resp == 1, nil
}
