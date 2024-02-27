package cmd

import (
	"github.com/unpackdev/downloader/services/query"
	"github.com/urfave/cli/v2"
)

func GetQueryCommands() []*cli.Command {
	return []*cli.Command{
		&cli.Command{
			Name:  "query",
			Usage: "Dataset querying related services",
			Subcommands: []*cli.Command{
				{
					Name:  "start",
					Usage: "Starts the query service",
					Flags: []cli.Flag{
						/*						&cli.StringFlag{
												Name:     "network",
												Required: true,
												Value:    utils.Ethereum.String(),
											},*/
					},
					Action: func(cCtx *cli.Context) error {
						return query.Run(cCtx)
					},
				},
			},
		},
	}
}
