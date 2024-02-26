package app

import (
	"context"
	"errors"
	"github.com/urfave/cli/v2"
	"os"
)

// Descriptor holds basic information about the CLI application.
type Descriptor struct {
	Name        string
	Version     string
	HelpName    string
	Description string
	Usage       string
}

// App represents an application with CLI commands.
// It embeds *cli.App from the urfave/cli package and adds context support.
type App struct {
	ctx context.Context
	*cli.App
}

// New initializes a new App instance with the provided context and descriptor.
// It returns an error if the initialization fails.
func New(ctx context.Context, desc Descriptor) (*App, error) {
	return &App{
		ctx: ctx,
		App: &cli.App{
			Name:        desc.Name,
			Version:     desc.Version,
			HelpName:    desc.HelpName,
			Description: desc.Description,
			Usage:       desc.Usage,
			Authors: []*cli.Author{
				{Name: "Nevio Vesic", Email: "info@unpack.dev"},
			},
			Commands:  make([]*cli.Command, 0),
			Reader:    os.Stdin,
			Writer:    os.Stdout,
			ErrWriter: os.Stderr,
		},
	}, nil
}

// RegisterCommands adds a slice of *cli.Command to the application.
// It returns an error if the application is not initialized.
func (a *App) RegisterCommands(commands []*cli.Command) error {
	if a.App == nil {
		return errors.New("application not initialized")
	}
	a.Commands = append(a.Commands, commands...)
	return nil
}

// Run executes the application with the provided command-line arguments.
// It delegates to *cli.App's Run method and returns any errors encountered.
func (a *App) Run(args []string) error {
	return a.App.Run(args)
}
