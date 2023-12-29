package schemas

import (
	// A work around to trick go mod tidy to include the package that is used by the generate.go
	// Otherwise it would complain that package does not exist as it would be removed by go mod tidy.
	_ "github.com/stoewer/go-strcase"
)
