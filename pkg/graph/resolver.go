//go:generate go run generate.go
package graph

import (
	"github.com/unpackdev/downloader/pkg/db"
)

// This file will not be regenerated automatically.
//
// It serves as dependency injection for your app, add any dependencies you require here.

type Resolver struct {
	Db *db.BadgerDB
}
