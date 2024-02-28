package graph

import (
	"context"
	"github.com/unpackdev/inspector/pkg/options"
	"strings"
)

func (r *queryResolver) resolveNetworks(ctx context.Context, networkID *int, name *string, symbol *string, suspended *bool, maintenance *bool) ([]*Network, error) {
	toReturn := make([]*Network, 0)

	for _, network := range options.G().Networks {
		if networkID != nil {
			if *networkID != network.NetworkId {
				continue
			}
		}

		if name != nil {
			networkName := strings.ToLower(network.Name)
			requestedName := strings.ToLower(*name)
			if !strings.Contains(networkName, requestedName) {
				continue
			}
		}

		if symbol != nil {
			networkSymbol := strings.ToLower(network.Symbol)
			requestedSymbol := strings.ToLower(*symbol)
			if !strings.Contains(networkSymbol, requestedSymbol) {
				continue
			}
		}

		if suspended != nil {
			if network.Suspended != *suspended {
				continue
			}
		}

		if maintenance != nil {
			if network.Maintenance != *maintenance {
				continue
			}
		}

		toReturn = append(toReturn, &Network{
			Name:          network.Name,
			NetworkID:     network.NetworkId,
			Symbol:        network.Symbol,
			CanonicalName: network.CanonicalName,
			Website:       network.Website,
			Suspended:     network.Suspended,
			Maintenance:   network.Maintenance,
		})
	}

	return toReturn, nil
}
