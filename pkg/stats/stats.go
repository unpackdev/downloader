package stats

import "context"

type Stats struct {
	ctx context.Context
}

func New(ctx context.Context) (*Stats, error) {
	toReturn := &Stats{ctx: ctx}
	return toReturn, nil
}
