package client

import "context"

type Client struct {
	ctx context.Context
}

func New(ctx context.Context) (*Client, error) {
	toReturn := &Client{ctx: ctx}

	return toReturn, nil
}
