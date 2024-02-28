package cmd

import (
	"github.com/unpackdev/inspector/services/syncer"
	"github.com/unpackdev/solgo/utils"
	"github.com/urfave/cli/v2"
	"golang.org/x/sync/errgroup"
)

func GetRunnerCommands() []*cli.Command {
	return []*cli.Command{
		&cli.Command{
			Name:  "start",
			Usage: "Starts all or selected downloader services",
			Flags: []cli.Flag{
				&cli.StringFlag{
					Name:     "network",
					Required: true,
					Value:    utils.Ethereum.String(),
				},
			},
			Action: func(cCtx *cli.Context) error {
				g, _ := errgroup.WithContext(cCtx.Context)

				g.Go(func() error {
					return syncer.Run(cCtx)
				})

				return g.Wait()
			},
		},
	}
}
