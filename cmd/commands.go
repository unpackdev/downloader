package cmd

import "github.com/urfave/cli/v2"

// registry holds a mapping from module names to slices of CLI commands.
// Each module name is associated with its relevant CLI commands.
// Currently, it includes commands for the "downloader" module.
var (
	registry = map[string][]*cli.Command{
		"downloader": GetDownloaderCommands(),
	}
)

// GetCommands returns the complete registry of CLI commands.
// This function provides access to all the registered commands for different modules of the application.
// It is typically used to initialize the CLI application with all the necessary commands.
func GetCommands() map[string][]*cli.Command {
	return registry
}
