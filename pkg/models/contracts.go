package models

import (
	"database/sql"
	"encoding/base64"
	"errors"
	"fmt"
	"github.com/ethereum/go-ethereum/common"
	"github.com/unpackdev/inspector/pkg/machine"
	"github.com/unpackdev/solgo/standards"
	"github.com/unpackdev/solgo/utils"
	"math/big"
	"strings"
	"time"
)

// ContractKeyPrefix is a constant defining the prefix for the database keys of contract entries.
const ContractKeyPrefix = "contract:entry"

type Contract struct {
	Id                   int64
	NetworkId            *big.Int
	BlockNumber          *big.Int
	BlockHash            common.Hash
	TransactionHash      common.Hash
	Address              common.Address
	Name                 string
	Standards            []standards.Standard
	Proxy                bool
	License              string
	CompilerVersion      string
	SolgoVersion         string
	Optimized            bool
	OptimizationRuns     uint64
	EVMVersion           string
	ABI                  string
	Verified             bool
	SourcesProvider      string
	VerificationProvider string
	ExecutionBytecode    []byte
	Bytecode             []byte
	SafetyState          utils.SafetyStateType
	SourceAvailable      bool
	SelfDestructed       bool
	ProxyImplementations []common.Address
	CompletedStates      []machine.State
	FailedStates         []machine.State
	Processed            bool
	Partial              bool
	CreatedAt            time.Time
	UpdatedAt            time.Time
}

func (c *Contract) EncodeCursor() string {
	by, _ := big.NewInt(c.Id).GobEncode()
	return base64.URLEncoding.EncodeToString(by)
}

// GetKey constructs and returns a unique key for the entry combining the prefix, network, networkID, and address.
func (c *Contract) GetKey() string {
	return strings.Join(
		[]string{
			ContractKeyPrefix,
			c.NetworkId.String(),
			c.Address.Hex(),
		},
		"-",
	)
}

func (c *Contract) IsCompleted() bool {
	return c.Processed && !c.Partial
}

// GetContractByUniqueIndex retrieves a single contract from the database based on a unique combination of network_id, block_number, and address.
func GetContractByUniqueIndex(db *sql.DB, networkId *big.Int, blockNumber *big.Int, address common.Address) (*Contract, error) {
	var contract Contract

	networkIdStr := networkId.Uint64()
	blockNumberStr := blockNumber.Uint64()
	var blockHash string
	var txHash string
	var standardsModel string
	var executionBytecode string
	var bytecode string
	var safetyState string
	var proxyImplementations string
	var completedStates string
	var failedStates string

	query := `
	SELECT 
	    id, network_id, block_number, block_hash, transaction_hash, address, name, 
		standards, proxy, license, compiler_version, solgo_version, optimized, optimization_runs, 
		evm_version, abi, verified, sources_provider, verification_provider,
	    execution_bytecode, bytecode, source_available, safety_state, self_destructed, 
	    proxy_implementations, completed_states, failed_states, processed, partial, created_at, updated_at
	FROM contracts 
	WHERE network_id = ? AND block_number = ? AND address = ?`

	row := db.QueryRow(query, networkIdStr, blockNumberStr, address)

	err := row.Scan(
		&contract.Id, &networkIdStr, &blockNumberStr, &blockHash, &txHash,
		&contract.Address, &contract.Name, &standardsModel, &contract.Proxy, &contract.License,
		&contract.CompilerVersion, &contract.SolgoVersion, &contract.Optimized,
		&contract.OptimizationRuns, &contract.EVMVersion, &contract.ABI,
		&contract.Verified, &contract.SourcesProvider, &contract.VerificationProvider,
		&executionBytecode, &bytecode, &contract.SourceAvailable, &safetyState,
		&contract.SelfDestructed, &proxyImplementations, &completedStates, &failedStates, &contract.Processed,
		&contract.Partial, &contract.CreatedAt, &contract.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, err
		}
		return nil, fmt.Errorf("error querying contract by unique index: %v", err)
	}

	// Convert the retrieved values back to their specific types
	contract.NetworkId = new(big.Int).SetUint64(networkIdStr)
	contract.BlockNumber = new(big.Int).SetUint64(blockNumberStr)
	contract.BlockHash = common.HexToHash(blockHash)
	contract.TransactionHash = common.HexToHash(txHash)
	contract.ExecutionBytecode = common.Hex2Bytes(executionBytecode)
	contract.Bytecode = common.Hex2Bytes(bytecode)
	contract.SafetyState = utils.SafetyStateType(safetyState)

	if err := utils.FromJSON([]byte(standardsModel), &contract.Standards); err != nil {
		return nil, fmt.Errorf(
			"failure to decode standards into contract: %w", err,
		)
	}

	if err := utils.FromJSON([]byte(proxyImplementations), &contract.ProxyImplementations); err != nil {
		return nil, fmt.Errorf(
			"failure to decode proxy implementations into contract: %w", err,
		)
	}

	if err := utils.FromJSON([]byte(completedStates), &contract.CompletedStates); err != nil {
		return nil, fmt.Errorf(
			"failure to decode completed states into contract: %w", err,
		)
	}

	if err := utils.FromJSON([]byte(failedStates), &contract.FailedStates); err != nil {
		return nil, fmt.Errorf(
			"failure to decode completed states into contract: %w", err,
		)
	}

	return &contract, nil
}

// SaveContract saves a Contract instance to the SQLite database.
func SaveContract(db *sql.DB, contract *Contract) error {
	// Prepare SQL insert statement
	stmt, err := db.Prepare(`
	INSERT INTO contracts(
		network_id, block_number, block_hash, transaction_hash, address, name, 
		standards, proxy, license, compiler_version, solgo_version, optimized, optimization_runs, 
		evm_version, abi, verified, sources_provider, verification_provider,
	    execution_bytecode, bytecode, source_available, safety_state, self_destructed, proxy_implementations,
		completed_states, failed_states, processed, partial, created_at, updated_at
	) VALUES(
		?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?
	)`)
	if err != nil {
		return fmt.Errorf("error preparing insert statement: %v", err)
	}
	defer stmt.Close()

	standardsJson, _ := utils.ToJSON(contract.Standards)
	proxyImplementationJson, _ := utils.ToJSON(contract.ProxyImplementations)
	completedStates, _ := utils.ToJSON(contract.CompletedStates)
	failedStates, _ := utils.ToJSON(contract.FailedStates)

	// Execute SQL statement
	_, err = stmt.Exec(
		contract.NetworkId.Uint64(),
		contract.BlockNumber.Uint64(),
		contract.BlockHash.Hex(),
		contract.TransactionHash.Hex(),
		contract.Address,
		contract.Name,
		string(standardsJson),
		contract.Proxy,
		contract.License,
		contract.CompilerVersion,
		contract.SolgoVersion,
		contract.Optimized,
		contract.OptimizationRuns,
		contract.EVMVersion,
		contract.ABI,
		contract.Verified,
		contract.SourcesProvider,
		contract.VerificationProvider,
		common.Bytes2Hex(contract.ExecutionBytecode),
		common.Bytes2Hex(contract.Bytecode),
		contract.SourceAvailable,
		contract.SafetyState.String(),
		contract.SelfDestructed,
		string(proxyImplementationJson),
		string(completedStates),
		string(failedStates),
		contract.Processed,
		contract.Partial,
		contract.CreatedAt,
		contract.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("error executing insert statement: %v", err)
	}

	return nil
}

// UpdateContract updates an existing Contract instance in the database.
func UpdateContract(db *sql.DB, contract *Contract) error {
	// Prepare SQL update statement
	stmt, err := db.Prepare(`UPDATE contracts SET 
        network_id=?, 
        block_number=?, 
        block_hash=?, 
        transaction_hash=?, 
        address=?, 
        name=?, 
        license=?, 
        compiler_version=?, 
        solgo_version=?, 
        optimized=?, 
        optimization_runs=?, 
        evm_version=?, 
        abi=?, 
        verified=?, 
        verification_provider=?, 
        processed=?, 
        partial=?, 
        created_at=?, 
        updated_at=? 
        WHERE id=?`)
	if err != nil {
		return fmt.Errorf("error preparing update statement: %v", err)
	}
	defer stmt.Close()

	// Execute SQL statement
	_, err = stmt.Exec(
		contract.NetworkId.Uint64(),
		contract.BlockNumber.Uint64(),
		contract.BlockHash.Hex(),
		contract.TransactionHash.Hex(),
		contract.Address,
		contract.Name,
		contract.License,
		contract.CompilerVersion,
		contract.SolgoVersion,
		contract.Optimized,
		contract.OptimizationRuns,
		contract.EVMVersion,
		contract.ABI,
		contract.Verified,
		contract.VerificationProvider,
		contract.Processed,
		contract.Partial,
		contract.CreatedAt,
		contract.UpdatedAt,
		contract.Id,
	)
	if err != nil {
		return fmt.Errorf("error executing update statement: %v", err)
	}

	return nil
}
