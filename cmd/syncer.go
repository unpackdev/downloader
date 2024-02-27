package cmd

import (
	"github.com/unpackdev/downloader/services/syncer"
	"github.com/unpackdev/solgo/utils"
	"github.com/urfave/cli/v2"
)

func GetSyncerCommands() []*cli.Command {
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
				{
					Name:  "one",
					Usage: "Synchronizes a specific contract by its address",
					Flags: []cli.Flag{
						&cli.StringFlag{
							Name:     "network",
							Required: true,
							Value:    utils.Ethereum.String(),
						},
						&cli.StringFlag{
							Name:     "addr",
							Required: true,
						},
					},
					Action: func(cCtx *cli.Context) error {
						service, err := syncer.New(cCtx)
						if err != nil {
							return err
						}

						return service.Unpack(cCtx)
					},
				},
			},
		},
	}
}
