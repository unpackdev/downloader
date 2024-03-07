//go:build ignore

package main

import (
	"fmt"
	"os"

	"github.com/99designs/gqlgen/api"
	"github.com/99designs/gqlgen/codegen/config"
	"github.com/unpackdev/inspector/schemas"
)

const (
	schemaPath = "../../schemas/dist/schema.graphqls"
)

func main() {
	schema, err := schemas.String()
	if err != nil {
		fmt.Fprintln(os.Stderr, "failed to load schema", err.Error())
		os.Exit(2)
	}

	if err := schemas.Remove(schemaPath); err != nil {
		fmt.Fprintln(os.Stderr, "failed to remove schema", err.Error())
		os.Exit(2)
	}

	if err := schemas.Write(schemaPath, schema); err != nil {
		fmt.Fprintln(os.Stderr, "failed to write new schema", err.Error())
		os.Exit(2)
	}

	cfg, err := config.LoadConfigFromDefaultLocations()
	if err != nil {
		fmt.Fprintln(os.Stderr, "failed to load config", err.Error())
		os.Exit(2)
	}

	// Attaching the mutation function onto modelgen plugin
	//p := modelgen.Plugin{}

	err = api.Generate(cfg)

	if err != nil {
		fmt.Fprintln(os.Stderr, err.Error())
		os.Exit(3)
	}

}
