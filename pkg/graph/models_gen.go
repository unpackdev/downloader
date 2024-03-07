// Code generated by github.com/99designs/gqlgen, DO NOT EDIT.

package graph

import (
	"time"
)

// A representation of a blockchain smart contract and its associated metadata.
type Contract struct {
	// The network information associated with this contract, detailing on which blockchain network the contract resides.
	Network *Network `json:"network"`
	// The blockchain address of the contract, serving as a unique identifier on the blockchain.
	Address string `json:"address"`
	// The name of the contract, providing a human-readable identifier.
	Name string `json:"name"`
	// The block number where the contract was deployed.
	BlockNumber int `json:"blockNumber"`
	// The hash of the block where the contract was deployed.
	BlockHash string `json:"blockHash"`
	// The hash of the transaction through which the contract was deployed.
	TransactionHash string `json:"transactionHash"`
	// A list of standards that the contract claims to implement, e.g., ERC20, ERC721.
	Standards []string `json:"standards,omitempty"`
	// The software license of the contract source code, if available.
	License *string `json:"license,omitempty"`
	// Indicates whether optimization was enabled during the contract's compilation.
	Optimized bool `json:"optimized"`
	// The number of optimization runs performed if optimization was enabled.
	OptimizationRuns int `json:"optimizationRuns"`
	// Indicates if the contract is a proxy contract.
	Proxy bool `json:"proxy"`
	// A list of addresses for contracts that are implementations of this proxy, if applicable.
	Implementations []string `json:"implementations,omitempty"`
	// The contract's ABI (Application Binary Interface) as a JSON string.
	Abi *string `json:"abi,omitempty"`
	// The bytecode executed during contract creation.
	ExecutionBytecode *string `json:"executionBytecode,omitempty"`
	// The bytecode of the contract as deployed on the blockchain.
	Bytecode *string `json:"bytecode,omitempty"`
	// The EVM (Ethereum Virtual Machine) version the contract was compiled for.
	EvmVersion *string `json:"evmVersion,omitempty"`
	// Indicates if the contract's source code has been verified.
	Verified bool `json:"verified"`
	// Indicates if the source code for the contract is available.
	SourceAvailable bool `json:"sourceAvailable"`
	// The provider from which the contract's sources were obtained, if available.
	SourcesProvider *string `json:"sourcesProvider,omitempty"`
	// The provider used for verifying the contract's source code, if verification was performed.
	VerificationProvider *string `json:"verificationProvider,omitempty"`
	// Indicates if the contract has been self-destructed.
	SelfDestructed bool `json:"selfDestructed"`
	// The version of the Solidity compiler used to compile this contract.
	CompilerVersion *string `json:"compilerVersion,omitempty"`
	// The version of the Solgo compiler used, if applicable.
	SolgoVersion *string `json:"solgoVersion,omitempty"`
	// The current processing state of the contract, indicating the stage in the contract's lifecycle.
	CurrentState string `json:"currentState"`
	// The next expected processing state of the contract, indicating the anticipated next step in processing.
	NextState string `json:"nextState"`
	// A list of states that have been completed in the processing of the contract, showing progress.
	CompletedStates []string `json:"completedStates"`
	// A list of states that have failed during the processing of the contract, indicating errors or issues.
	FailedStates []string `json:"failedStates"`
	// Indicates if the processing of the contract has been completed.
	Completed bool `json:"completed"`
	// Indicates if the contract has been only partially processed, potentially due to errors or interruptions.
	Partial bool `json:"partial"`
	// The timestamp indicating when the contract data was initially created in the database.
	CreatedAt time.Time `json:"createdAt"`
	// The timestamp indicating the last time the contract data was updated in the database.
	UpdatedAt time.Time `json:"updatedAt"`
}

// A connection to a list of contracts, providing pagination capabilities.
type ContractConnection struct {
	// A list of contract edges, representing the contracts in this connection.
	Edges []*ContractEdge `json:"edges"`
	// Metadata that provides information about the current page of results.
	PageInfo *PageInfo `json:"pageInfo"`
}

// Represents an individual contract as part of a paginated list (connection).
type ContractEdge struct {
	// The actual contract data.
	Node *Contract `json:"node"`
	// A unique identifier used for pagination, marking the position of this contract in the overall list.
	Cursor string `json:"cursor"`
}

// Request Input type for specifying a contract address and its corresponding network ID for unpacking.
type ContractUnpackRequest struct {
	// The blockchain address of the contract to be unpacked.
	Address string `json:"address"`
	// The ID of the network where the contract resides.
	NetworkID int `json:"networkId"`
}

// Mutation to submit one or more contracts for unpacking based on their addresses and network IDs.
// After unpacking, it returns a connection to the affected or related contracts, allowing for pagination and further inspection.
type Mutations struct {
}

// A representation of a network with its essential details.
type Network struct {
	// Official (chain) ID of the network.
	NetworkID int `json:"networkId"`
	// Name of the network.
	Name string `json:"name"`
	// Official or recognized name of the network.
	CanonicalName string `json:"canonicalName"`
	// Short symbol representation of the network.
	Symbol string `json:"symbol"`
	// Website URL of the network.
	Website string `json:"website"`
	// Flag indicating if the network is suspended.
	Suspended bool `json:"suspended"`
	// Flag indicating if the network is under maintenance.
	Maintenance bool `json:"maintenance"`
}

// Information about pagination in a connection.
type PageInfo struct {
	// Indicates if there are more items following the current set.
	HasNextPage bool `json:"hasNextPage"`
	// Indicates if there are more items preceding the current set.
	HasPreviousPage bool `json:"hasPreviousPage"`
	// The cursor for the first item in the current set.
	StartCursor string `json:"startCursor"`
	// The cursor for the last item in the current set.
	EndCursor string `json:"endCursor"`
}

// Defines the queries available on the network.
type Query struct {
}
