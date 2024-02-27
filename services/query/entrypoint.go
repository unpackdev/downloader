package query

import (
	"fmt"
	"github.com/urfave/cli/v2"
)

func Run(ctx *cli.Context) error {
	service, err := NewService(ctx.Context)
	if err != nil {
		return err
	}

	if err := service.Start(); err != nil {
		return fmt.Errorf(
			"failure to start syncer service: %s",
			err,
		)
	}

	return nil
}
