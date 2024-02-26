package syncer

import (
	"fmt"
	"github.com/unpackdev/solgo/utils"
	"github.com/urfave/cli/v2"
)

func Run(ctx *cli.Context) error {
	service, err := NewService(ctx.Context)
	if err != nil {
		return err
	}

	network, err := utils.GetNetworkFromString(ctx.String("network"))
	if err != nil {
		return fmt.Errorf(
			"failure to discover provided network '%s'", ctx.String("network"),
		)
	}

	networkId := utils.GetNetworkID(network)

	if err := service.Start(network, networkId); err != nil {
		return fmt.Errorf(
			"failure to start syncer service: %s",
			err,
		)
	}

	return nil
}

func New(ctx *cli.Context) (*Service, error) {
	service, err := NewService(ctx.Context)
	if err != nil {
		return nil, err
	}
	return service, nil
}
