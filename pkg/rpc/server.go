package rpc

import (
	"context"
	"errors"
	"github.com/gorilla/websocket"
	"io"
	"net"
	"net/http"
	"net/rpc"
	"net/rpc/jsonrpc"
	"time"

	"github.com/unpackdev/inspector/pkg/options"
	"go.uber.org/zap"
)

// Handler represents an RPC handler interface
type Handler interface{}

type readWriteCloser struct {
	io.Reader
	io.Writer
}

func (rwc readWriteCloser) Close() error {
	return nil // no-op Close method
}

// Server represents a JSON-RPC server
type Server struct {
	ctx      context.Context
	listener net.Listener
	opts     options.Rpc
	server   *rpc.Server
	upgrader websocket.Upgrader
}

// NewServer creates a new RpcServer instance
func NewServer(ctx context.Context, opts options.Rpc) (*Server, error) {
	return &Server{
		ctx:    ctx,
		opts:   opts,
		server: rpc.NewServer(),
		upgrader: websocket.Upgrader{
			ReadBufferSize:  1024,
			WriteBufferSize: 1024,
			CheckOrigin: func(r *http.Request) bool {
				// Check the origin of the request, and decide whether to upgrade.
				// For simplicity, allowing all origins here:
				return true
			},
		},
	}, nil
}

// RegisterHandler registers a new handler with the RPC server
func (s *Server) RegisterHandler(name string, handler Handler) error {
	return s.server.RegisterName(name, handler)
}

// Start starts the RPC server on the specified network address
func (s *Server) Start() error {
	l, err := net.Listen("tcp", s.opts.Addr)
	if err != nil {
		return err
	}
	s.listener = l

	http.HandleFunc("/rpc", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != "POST" {
			http.Error(w, "Only POST method is allowed", http.StatusMethodNotAllowed)
			return
		}

		codec := jsonrpc.NewServerCodec(readWriteCloser{Reader: r.Body, Writer: w})
		defer r.Body.Close()

		if err := s.server.ServeRequest(codec); err != nil {
			zap.L().Error(
				"failure while serving rpc request",
				zap.Error(err),
			)
		}
	})

	server := &http.Server{
		Handler: http.DefaultServeMux,
	}

	go func() {
		zap.L().Info("RPC Server started on", zap.String("addr", s.opts.Addr+"/rpc"))
		if err := server.Serve(s.listener); errors.Is(err, http.ErrServerClosed) {
			zap.L().Error("failure to serve RPC server", zap.Error(err))
		}
	}()

	select {
	case <-s.ctx.Done():
		zap.L().Info("Shutting down server...")
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		if err := server.Shutdown(ctx); err != nil {
			zap.L().Fatal("Server shutdown failed", zap.Error(err))
		}
		zap.L().Info("Server gracefully stopped")
	}

	return nil
}
