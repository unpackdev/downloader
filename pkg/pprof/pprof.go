package pprof

import (
	"context"
	"github.com/unpackdev/inspector/pkg/options"
	"go.uber.org/zap"
	"net/http"
	_ "net/http/pprof"
)

// Pprof encapsulates the pprof server configuration.
type Pprof struct {
	ctx  context.Context
	opts options.Pprof
}

// New creates a new Pprof instance with the specified listen address.
func New(ctx context.Context, opts options.Pprof) *Pprof {
	return &Pprof{ctx: ctx, opts: opts}
}

// Start initializes the pprof HTTP server on the configured address.
func (p *Pprof) Start() error {
	zap.L().Info(
		"Started up pprof server",
		zap.String("address", p.opts.Addr),
	)

	return http.ListenAndServe(p.opts.Addr, nil)
}
