package cmd

import (
	"github.com/urfave/cli/v2"
)

func GetDownloaderCommands() []*cli.Command {
	return []*cli.Command{
		&cli.Command{
			Name:  "downloader",
			Usage: "Download and manage blockchain smart contract information",
			Subcommands: []*cli.Command{
				{
					Name:  "start",
					Usage: "Starts the downloader service",
					Flags: []cli.Flag{},
					Action: func(cCtx *cli.Context) error {
						return nil
					},
				},
			},
		},
	}
}
