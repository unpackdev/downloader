package graph

// This file will be automatically regenerated based on the schema, any resolver implementations
// will be copied through when generating and any unknown code will be moved to the end.
// Code generated by github.com/99designs/gqlgen version v0.17.41

import (
	"context"
	"github.com/unpackdev/downloader/pkg/options"
	"strings"
)

// Networks is the resolver for the networks field. It is deliberately loaded from the configuration
// as networks change very infrequently, and you'd need to download new release regardless. No need to store them
// into the database...
// There is no need for any type of caching for this endpoint.
func (r *queryResolver) Networks(ctx context.Context, networkID *int, name *string, symbol *string, suspended *bool, maintenance *bool) ([]*Network, error) {
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

// Contracts is the resolver for the contracts field.
func (r *queryResolver) Contracts(ctx context.Context, networkIds []int, blockNumbers []int, blockHashes []string, transactionHashes []string, addresses []string, limit *int, first *int, after *string) (*ContractConnection, error) {
	toReturn := &ContractConnection{}

	return toReturn, nil
}

// Query returns QueryResolver implementation.
func (r *Resolver) Query() QueryResolver { return &queryResolver{r} }

type queryResolver struct{ *Resolver }
