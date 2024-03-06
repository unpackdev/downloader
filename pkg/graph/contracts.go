package graph

import (
	"context"
	"fmt"
	"github.com/unpackdev/inspector/pkg/models"
	"github.com/unpackdev/inspector/pkg/options"
	"math/big"
	"strings"
)

func (r *queryResolver) resolveContracts(ctx context.Context, networkIds []int, blockNumbers []int, blockHashes []string, transactionHashes []string, addresses []string, limit *int, first *int, after *string) (*ContractConnection, error) {
	// Initialize the return structure with empty slices
	toReturn := &ContractConnection{
		Edges:    []*ContractEdge{},
		PageInfo: &PageInfo{},
	}

	var actualLimit int
	if limit != nil {
		actualLimit = *limit
	} else {
		actualLimit = 10 // Default limit value
	}

	var startAfter *big.Int
	var err error
	if after != nil {
		startAfter, err = models.DecodeCursor(*after)
		if err != nil {
			return nil, fmt.Errorf("cannot decode 'after' into its appropriate representation: %s", err)
		}
	} else {
		startAfter = big.NewInt(0) // Start from the beginning if 'after' is not provided
	}

	// Construct the query dynamically based on provided filters
	var queryBuilder strings.Builder
	queryBuilder.WriteString(
		`SELECT 
    			id, network_id, block_number, block_hash, transaction_hash,
    			address, name, license, optimized, optimization_runs, proxy,
    			created_at, updated_at 
			FROM contracts WHERE id > ?`,
	)
	args := []interface{}{startAfter.Int64()}

	if len(networkIds) > 0 {
		queryBuilder.WriteString("AND network_id IN (")
		for i, id := range networkIds {
			if i > 0 {
				queryBuilder.WriteString(",")
			}
			queryBuilder.WriteString("?")
			args = append(args, id)
		}
		queryBuilder.WriteString(") ")
	}

	if len(addresses) > 0 {
		queryBuilder.WriteString("AND address IN (")
		for i, addr := range addresses {
			if i > 0 {
				queryBuilder.WriteString(",")
			}
			queryBuilder.WriteString("?")
			args = append(args, addr)
		}
		queryBuilder.WriteString(") ")
	}

	queryBuilder.WriteString("ORDER BY id ASC LIMIT ?")
	args = append(args, actualLimit)

	fmt.Println(args)

	// Execute the query
	rows, err := r.Db.GetDB().QueryContext(ctx, queryBuilder.String(), args...)
	if err != nil {
		return nil, fmt.Errorf("error executing query: %v", err)
	}
	defer rows.Close()

	for rows.Next() {
		var edge ContractEdge
		var contract models.Contract
		var networkId uint64
		var blockNumber uint64
		var txHash string
		var blockHash string

		err := rows.Scan(
			&contract.Id, &networkId, &blockNumber, &blockHash, &txHash, &contract.Address,
			&contract.Name, &contract.License, &contract.Optimized, &contract.OptimizationRuns,
			&contract.Proxy, &contract.CreatedAt, &contract.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("error scanning row: %v", err)
		}

		network, _ := options.G().GetNetworkById(networkId)

		edge.Node = &Contract{
			Network: &Network{
				Name:          network.Name,
				NetworkID:     network.NetworkId,
				Symbol:        network.Symbol,
				CanonicalName: network.CanonicalName,
				Website:       network.Website,
				Suspended:     network.Suspended,
				Maintenance:   network.Maintenance,
			},
			Address:          contract.Address.Hex(),
			Name:             contract.Name,
			BlockNumber:      int(blockNumber),
			BlockHash:        blockHash,
			TransactionHash:  txHash,
			License:          &contract.License,
			Optimized:        contract.Optimized,
			OptimizationRuns: int(contract.OptimizationRuns),
			//Proxy:            contract.Proxy,
			//Implementations:  entry.ImplementationAddrs,
			SolgoVersion: &contract.SolgoVersion,
		}

		edge.Cursor = contract.EncodeCursor()
		toReturn.Edges = append(toReturn.Edges, &edge)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating rows: %v", err)
	}

	// Set PageInfo based on the results
	if len(toReturn.Edges) > 0 {
		toReturn.PageInfo.StartCursor = toReturn.Edges[0].Cursor
		toReturn.PageInfo.EndCursor = toReturn.Edges[len(toReturn.Edges)-1].Cursor
		toReturn.PageInfo.HasNextPage = len(toReturn.Edges) == actualLimit
	}

	return toReturn, nil
}
