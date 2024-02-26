package cmd

import (
	"github.com/unpackdev/downloader/services/syncer"
	"github.com/unpackdev/solgo/utils"
	"github.com/urfave/cli/v2"
)

func GetDownloaderCommands() []*cli.Command {
	return []*cli.Command{
		&cli.Command{
			Name:  "syncer",
			Usage: "Downloads and syncs blockchain smart contract information",
			Subcommands: []*cli.Command{
				{
					Name:  "start",
					Usage: "Starts the downloader service",
					Flags: []cli.Flag{
						&cli.StringFlag{
							Name:     "network",
							Required: true,
							Value:    utils.Ethereum.String(),
						},
					},
					Action: func(cCtx *cli.Context) error {
						return syncer.Run(cCtx)
					},
				},
			},
		},
	}
}
