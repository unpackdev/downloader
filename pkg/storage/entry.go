package storage

import (
	"encoding/json"
	"math/big"
	"strings"
	"time"

	"github.com/ethereum/go-ethereum/common"
	"github.com/unpackdev/solgo"
	"github.com/unpackdev/solgo/utils"
)

// ENTRY_KEY_PREFIX is a constant defining the prefix for the database keys of contract entries.
const ENTRY_KEY_PREFIX = "contract:entry"

// Entry represents a record of an Ethereum contract with various attributes such as network details,
// block information, contract address, and metadata.
type Entry struct {
	Network              utils.Network   `json:"network"`
	NetworkID            utils.NetworkID `json:"network_id"`
	BlockNumber          *big.Int        `json:"block_number"`
	BlockHash            common.Hash     `json:"block_hash"`
	TransactionHash      common.Hash     `json:"transaction_hash"`
	Address              common.Address  `json:"address"`
	Path                 string          `json:"path"`
	License              string          `json:"license"`
	Optimized            bool            `json:"optimized"`
	OptimizationRuns     uint64          `json:"optimization_runs"`
	Name                 string          `json:"name"`
	CompilerVersion      string          `json:"compiler_version"`
	EVMVersion           string          `json:"evm_version"`
	ABI                  string          `json:"abi"`
	SourcesProvider      string          `json:"sources_provider"`
	Verified             bool            `json:"verified"`
	VerificationProvider string          `json:"verification_provider"`
	InsertedAt           time.Time       `json:"inserted_at"`
}

// NewEntry creates and returns a new Entry instance with provided parameters and current UTC time.
func NewEntry(
	network utils.Network, networkID utils.NetworkID, blockNumber *big.Int, blockHash common.Hash,
	transactionHash common.Hash, address common.Address, path string,
) *Entry {
	return &Entry{
		Network:         network,
		NetworkID:       networkID,
		BlockNumber:     blockNumber,
		BlockHash:       blockHash,
		TransactionHash: transactionHash,
		Address:         address,
		Path:            path,
		InsertedAt:      time.Now().UTC(),
	}
}

// GetKey constructs and returns a unique key for the entry combining the prefix, network, networkID, and address.
func (e *Entry) GetKey() string {
	return strings.Join(
		[]string{
			ENTRY_KEY_PREFIX,
			e.Network.String(),
			e.NetworkID.String(),
			e.Address.Hex(),
		},
		"-",
	)
}

// GetNetwork returns the network of the entry.
func (e *Entry) GetNetwork() utils.Network {
	return e.Network
}

// GetNetworkID returns the network ID of the entry.
func (e *Entry) GetNetworkID() utils.NetworkID {
	return e.NetworkID
}

// GetBlockNumber returns the block number of the entry.
func (e *Entry) GetBlockNumber() *big.Int {
	return e.BlockNumber
}

// GetBlockHash returns the block hash of the entry.
func (e *Entry) GetBlockHash() common.Hash {
	return e.BlockHash
}

// GetTransactionHash returns the transaction hash of the entry.
func (e *Entry) GetTransactionHash() common.Hash {
	return e.TransactionHash
}

// GetPath returns the path of the entry.
func (e *Entry) GetPath() string {
	return e.Path
}

// GetSources retrieves the solgo.Sources associated with the entry's path and name.
func (e *Entry) GetSources() (*solgo.Sources, error) {
	return solgo.NewSourcesFromPath(e.Name, e.Path)
}

// MarshalBinary serializes the Entry into JSON format.
// Returns an error if JSON marshaling fails.
func (e *Entry) MarshalBinary() ([]byte, error) {
	return json.Marshal(e)
}

// UnmarshalBinary deserializes the provided data into the Entry.
// Returns an error if JSON unmarshaling fails.
func (e *Entry) UnmarshalBinary(data []byte) error {
	return json.Unmarshal(data, e)
}

// ToBytes serializes the Entry into a byte slice.
// Logs an error if marshaling fails, but still returns the bytes.
func (e *Entry) ToBytes() []byte {
	data, err := e.MarshalBinary()
	if err != nil {
		// Log the error here.
	}
	return data
}
