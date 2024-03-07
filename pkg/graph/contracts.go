package graph

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"github.com/doug-martin/goqu/v9"
	_ "github.com/doug-martin/goqu/v9/dialect/sqlite3"
	"github.com/ethereum/go-ethereum/common"
	"github.com/unpackdev/inspector/pkg/models"
	"github.com/unpackdev/inspector/pkg/options"
	"github.com/unpackdev/solgo/utils"
	"math/big"
)

func (r *queryResolver) resolveContracts(ctx context.Context, networkIds []int, blockNumbers []int, blockHashes []string, transactionHashes []string, addresses []string, limit *int, first *int, after *string) (*ContractConnection, error) {
	toReturn := &ContractConnection{
		Edges:    []*ContractEdge{},
		PageInfo: &PageInfo{},
	}

	actualLimit := 10
	if limit != nil {
		actualLimit = *limit
	}

	var startAfter *big.Int
	var err error
	if after != nil {
		startAfter, err = models.DecodeCursor(*after)
		if err != nil {
			return nil, fmt.Errorf("cannot decode 'after' into its appropriate representation: %w", err)
		}
	} else {
		startAfter = big.NewInt(0) // Start from the beginning if 'after' is not provided
	}

	preloads := GetPreloads(ctx)

	// TODO: Select only what is necessary by looking into the preloads
	// We need to ensure that select is modified as well as scanner part in order for preloads to work
	// This will speed up the result processing...
	dialect := goqu.Dialect("sqlite3")
	selectDsl := dialect.From("contracts").Select(
		"id", "network_id", "block_number", "block_hash", "transaction_hash", "address", "name",
		"standards", "proxy", "license", "compiler_version", "solgo_version", "optimized",
		"optimization_runs", "evm_version", "abi", "verified", "sources_provider", "verification_provider",
		"execution_bytecode", "bytecode", "source_available", "safety_state", "self_destructed", "proxy_implementations",
		"completed_states", "failed_states", "processed", "partial", "created_at", "updated_at",
	).Where(goqu.Ex{
		"id": goqu.Op{"gt": startAfter.Int64()},
	}).Order(goqu.C("id").Asc()).Limit(uint(actualLimit))

	if networkIds != nil && len(networkIds) > 0 {
		selectDsl = selectDsl.Where(goqu.C("network_id").In(networkIds))
	}

	if addresses != nil && len(addresses) > 0 {
		selectDsl = selectDsl.Where(goqu.C("address").In(networkIds))
	}

	if blockNumbers != nil && len(blockNumbers) > 0 {
		selectDsl = selectDsl.Where(goqu.C("block_number").In(blockNumbers))
	}

	if blockHashes != nil && len(blockHashes) > 0 {
		selectDsl = selectDsl.Where(goqu.C("block_hash").In(blockHashes))
	}

	if transactionHashes != nil && len(transactionHashes) > 0 {
		selectDsl = selectDsl.Where(goqu.C("transaction_hash").In(transactionHashes))
	}

	query, params, err := selectDsl.ToSQL()
	if err != nil {
		return nil, fmt.Errorf("error preparing query: %w", err)
	}

	rows, err := r.Db.GetDB().QueryContext(ctx, query, params...)
	if err != nil {
		return nil, fmt.Errorf("error executing query: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var edge ContractEdge
		var contract models.Contract

		err := rows.Scan(
			&contract.Id, &contract.NetworkId, &contract.BlockNumber, &contract.BlockHash, &contract.TransactionHash, &contract.Address,
			&contract.Name, &contract.Standards, &contract.Proxy, &contract.License, &contract.CompilerVersion,
			&contract.SolgoVersion, &contract.Optimized, &contract.OptimizationRuns,
			&contract.EVMVersion, &contract.ABI, &contract.Verified, &contract.SourcesProvider,
			&contract.VerificationProvider, &contract.ExecutionBytecode, &contract.Bytecode, &contract.SourceAvailable,
			&contract.SafetyState, &contract.SelfDestructed, &contract.ProxyImplementations,
			&contract.CompletedStates, &contract.FailedStates, &contract.Processed, &contract.Partial,
			&contract.CreatedAt, &contract.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("error scanning row: %w", err)
		}

		network, _ := options.G().GetNetworkById(contract.NetworkId.Uint64())

		edge.Node = &Contract{
			Address:              contract.Address.Hex(),
			Standards:            contract.Standards.StringArray(),
			Name:                 contract.Name,
			BlockNumber:          int(contract.BlockNumber.Uint64()),
			BlockHash:            contract.BlockHash.Hex(),
			TransactionHash:      contract.TransactionHash.Hex(),
			License:              &contract.License,
			Optimized:            contract.Optimized,
			OptimizationRuns:     int(contract.OptimizationRuns),
			Proxy:                contract.Proxy,
			Implementations:      contract.ProxyImplementations.StringArray(),
			SolgoVersion:         &contract.SolgoVersion,
			CompilerVersion:      &contract.CompilerVersion,
			EvmVersion:           &contract.EVMVersion,
			Verified:             contract.Verified,
			SourceAvailable:      contract.SourceAvailable,
			SourcesProvider:      &contract.SourcesProvider,
			VerificationProvider: &contract.VerificationProvider,
			SelfDestructed:       contract.SelfDestructed,
			Abi:                  &contract.ABI,
			ExecutionBytecode:    contract.ExecutionBytecode.ToHexPtr(),
			Bytecode:             contract.Bytecode.ToHexPtr(),
			CompletedStates:      contract.CompletedStates.StringArray(),
			FailedStates:         contract.FailedStates.StringArray(),
			Completed:            contract.Processed,
			Partial:              contract.Partial,
			CreatedAt:            contract.CreatedAt,
			UpdatedAt:            contract.UpdatedAt,
		}

		if utils.StringInSlice("edges.node.network", preloads) {
			edge.Node.Network = &Network{
				Name:          network.Name,
				NetworkID:     network.NetworkId,
				Symbol:        network.Symbol,
				CanonicalName: network.CanonicalName,
				Website:       network.Website,
				Suspended:     network.Suspended,
				Maintenance:   network.Maintenance,
			}
		}

		edge.Cursor = contract.EncodeCursor()
		toReturn.Edges = append(toReturn.Edges, &edge)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating rows: %w", err)
	}

	if len(toReturn.Edges) > 0 {
		toReturn.PageInfo.StartCursor = toReturn.Edges[0].Cursor
		toReturn.PageInfo.EndCursor = toReturn.Edges[len(toReturn.Edges)-1].Cursor
		toReturn.PageInfo.HasNextPage = len(toReturn.Edges) == actualLimit
	}

	return toReturn, nil
}

func (r *mutationResolver) resolveContract(ctx context.Context, networkId int64, address common.Address) (*Contract, error) {
	dialect := goqu.Dialect("sqlite3")
	selectDsl := dialect.From("contracts").Select(
		"id", "network_id", "block_number", "block_hash", "transaction_hash", "address", "name",
		"standards", "proxy", "license", "compiler_version", "solgo_version", "optimized",
		"optimization_runs", "evm_version", "abi", "verified", "sources_provider", "verification_provider",
		"execution_bytecode", "bytecode", "source_available", "safety_state", "self_destructed", "proxy_implementations",
		"completed_states", "failed_states", "processed", "partial", "created_at", "updated_at",
	).Where(goqu.Ex{
		"network_id": goqu.Op{"eq": networkId},
		"address":    goqu.Op{"eq": address.Hex()},
	})

	query, params, err := selectDsl.ToSQL()
	if err != nil {
		return nil, fmt.Errorf("error preparing query: %w", err)
	}

	fmt.Println(query)

	row := r.Db.GetDB().QueryRowContext(ctx, query, params...)
	if err := row.Err(); err != nil {
		return nil, fmt.Errorf("error executing query: %w", err)
	}

	var contract models.Contract

	err = row.Scan(
		&contract.Id, &contract.NetworkId, &contract.BlockNumber, &contract.BlockHash, &contract.TransactionHash, &contract.Address,
		&contract.Name, &contract.Standards, &contract.Proxy, &contract.License, &contract.CompilerVersion,
		&contract.SolgoVersion, &contract.Optimized, &contract.OptimizationRuns,
		&contract.EVMVersion, &contract.ABI, &contract.Verified, &contract.SourcesProvider,
		&contract.VerificationProvider, &contract.ExecutionBytecode, &contract.Bytecode, &contract.SourceAvailable,
		&contract.SafetyState, &contract.SelfDestructed, &contract.ProxyImplementations,
		&contract.CompletedStates, &contract.FailedStates, &contract.Processed, &contract.Partial,
		&contract.CreatedAt, &contract.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, fmt.Errorf("contract not found")
		}

		return nil, fmt.Errorf("error scanning row: %w", err)
	}

	network, _ := options.G().GetNetworkById(contract.NetworkId.Uint64())

	return &Contract{
		Network: &Network{
			Name:          network.Name,
			NetworkID:     network.NetworkId,
			Symbol:        network.Symbol,
			CanonicalName: network.CanonicalName,
			Website:       network.Website,
			Suspended:     network.Suspended,
			Maintenance:   network.Maintenance,
		},
		Address:              contract.Address.Hex(),
		Standards:            contract.Standards.StringArray(),
		Name:                 contract.Name,
		BlockNumber:          int(contract.BlockNumber.Uint64()),
		BlockHash:            contract.BlockHash.Hex(),
		TransactionHash:      contract.TransactionHash.Hex(),
		License:              &contract.License,
		Optimized:            contract.Optimized,
		OptimizationRuns:     int(contract.OptimizationRuns),
		Proxy:                contract.Proxy,
		Implementations:      contract.ProxyImplementations.StringArray(),
		SolgoVersion:         &contract.SolgoVersion,
		CompilerVersion:      &contract.CompilerVersion,
		EvmVersion:           &contract.EVMVersion,
		Verified:             contract.Verified,
		SourceAvailable:      contract.SourceAvailable,
		SourcesProvider:      &contract.SourcesProvider,
		VerificationProvider: &contract.VerificationProvider,
		SelfDestructed:       contract.SelfDestructed,
		Abi:                  &contract.ABI,
		ExecutionBytecode:    contract.ExecutionBytecode.ToHexPtr(),
		Bytecode:             contract.Bytecode.ToHexPtr(),
		CompletedStates:      contract.CompletedStates.StringArray(),
		FailedStates:         contract.FailedStates.StringArray(),
		Completed:            contract.Processed,
		Partial:              contract.Partial,
		CreatedAt:            contract.CreatedAt,
		UpdatedAt:            contract.UpdatedAt,
	}, nil
}
