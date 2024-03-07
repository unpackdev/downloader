//go:generate go run generate.go
package graph

import (
	"github.com/nats-io/nats.go"
	"github.com/unpackdev/inspector/pkg/db"
)

// This file will not be regenerated automatically.
//
// It serves as dependency injection for your app, add any dependencies you require here.

type Resolver struct {
	Db   *db.Db
	Nats *nats.Conn
}
