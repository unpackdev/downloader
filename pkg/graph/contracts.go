package graph

import (
	"context"
)

func (r *queryResolver) resolveContracts(ctx context.Context, networkIds []int, blockNumbers []int, blockHashes []string, transactionHashes []string, addresses []string, limit *int, first *int, after *string) (*ContractConnection, error) {
	// Initialize the return structure with empty slices
	toReturn := &ContractConnection{
		Edges:    []*ContractEdge{},
		PageInfo: &PageInfo{},
	}

	/*	var actualLimit int
		if limit != nil {
			actualLimit = *limit
		} else {
			actualLimit = 10
		}

		var startAfter *big.Int
		var err error
		if after != nil {
			startAfter, err = storage.DecodeCursor(*after)
			if err != nil {
				return nil, fmt.Errorf("cannot decode after into its appropriate representation: %s", err)
			}
		} else {
			// If `after` is not provided, start from the beginning
			startAfter = big.NewInt(0) // or use nil and later check for nil before comparison
		}

		// Counter to keep track of the number of collected entries
		count := 0

		err = r.Storage.Seek(ctx, func(entry *storage.Entry) (bool, error) {
			// Implement your filtering logic here based on networkIds, blockNumbers, etc.

			if (startAfter == nil || entry.ID.Cmp(startAfter) > 0) && count < actualLimit {
				// No need to parse error as we won't discover unsupported networks inside.
				// Network needs to be resolved to write record in the first place...
				network, _ := options.G().GetNetworkById(entry.NetworkID.Uint64())

				toReturn.Edges = append(toReturn.Edges, &ContractEdge{
					Node: &Contract{
						Network: &Network{
							Name:          network.Name,
							NetworkID:     network.NetworkId,
							Symbol:        network.Symbol,
							CanonicalName: network.CanonicalName,
							Website:       network.Website,
							Suspended:     network.Suspended,
							Maintenance:   network.Maintenance,
						},
						Address:          entry.Address.Hex(),
						Name:             entry.Name,
						BlockNumber:      int(entry.BlockNumber.Uint64()),
						BlockHash:        entry.BlockHash.Hex(),
						TransactionHash:  entry.TransactionHash.Hex(),
						License:          &entry.License,
						Optimized:        entry.Optimized,
						OptimizationRuns: int(entry.OptimizationRuns),
						Proxy:            entry.Proxy,
						//Implementations:  entry.ImplementationAddrs,
						SolgoVersion: &entry.SolgoVersion,
					},
					Cursor: entry.EncodeCursor(),
				})
				count++
			}

			// Continue seeking if we haven't reached the limit yet
			return count < actualLimit, nil
		})

		if err != nil {
			zap.L().Error("failure to seek the storage", zap.Error(err))
			return nil, err
		}

		// Set PageInfo based on the collected entries
		if len(toReturn.Edges) > 0 {
			toReturn.PageInfo.StartCursor = toReturn.Edges[0].Cursor
			toReturn.PageInfo.EndCursor = toReturn.Edges[len(toReturn.Edges)-1].Cursor
			toReturn.PageInfo.HasNextPage = count == actualLimit
			// HasPreviousPage can be set based on the presence of an "after" cursor, but accurate determination may require additional checks
		}*/

	return toReturn, nil
}
