package models

import (
	"encoding/json"
	"github.com/ethereum/go-ethereum/common"
	"github.com/unpackdev/solgo/standards"
	"github.com/unpackdev/solgo/utils"
	"math/big"
	"time"
)

type Contract struct {
	Id                   int64
	NetworkId            int64
	BlockNumber          *big.Int
	TransactionHash      common.Hash
	Address              string
	Name                 string
	Standards            []standards.Standard
	License              string
	CompilerVersion      string
	SolgoVersion         string
	Optimized            bool
	OptimizationRuns     uint64
	EVMVersion           string
	ABI                  json.RawMessage
	Verified             bool
	VerificationProvider string
	SafetyState          utils.SafetyStateType
	Processed            bool
	Partial              bool
	CreatedAt            time.Time
	UpdatedAt            time.Time
}
