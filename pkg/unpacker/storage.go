package unpacker

import (
	"fmt"
	"github.com/unpackdev/inspector/pkg/models"
	"github.com/unpackdev/inspector/pkg/models/types"
	"github.com/unpackdev/solgo/standards"
	"github.com/unpackdev/solgo/utils"
	"path/filepath"
	"strings"
	"time"
)

func (d *Descriptor) GetStorageCachePath() string {
	return filepath.Join(
		fmt.Sprintf("_%s", strings.ToLower(d.Network.String())),
		// This is hardcoded for now... Not sure if I personally ever want to support testnet contracts
		"mainnet",
		// It will always be contracts and nothing else, therefore, hand-coded.
		"contracts",
		d.Header.Number.String(),
		d.Addr.Hex(),
	)
}

func (d *Descriptor) GetContractEntry() *models.Contract {
	descriptor := d.GetContract().GetDescriptor()

	toReturn := &models.Contract{
		NetworkId:            types.NewBigInt(d.NetworkID.ToBig()),
		BlockNumber:          types.NewBigInt(d.Header.Number),
		BlockHash:            types.NewHash(d.Header.Hash()),
		TransactionHash:      types.NewHash(d.Tx.Hash()),
		Address:              types.NewAddress(d.GetAddr()),
		Name:                 descriptor.GetName(),
		Standards:            make([]standards.Standard, 0),
		Proxy:                descriptor.Proxy,
		License:              descriptor.GetLicense(),
		Optimized:            descriptor.IsOptimized(),
		OptimizationRuns:     descriptor.GetOptimizationRuns(),
		ABI:                  descriptor.GetABI(),
		SourcesProvider:      descriptor.GetSourcesProvider(),
		Verified:             descriptor.IsVerified(),
		VerificationProvider: descriptor.GetVerificationProvider(),
		EVMVersion:           strings.ToLower(descriptor.GetEVMVersion()),
		SolgoVersion:         descriptor.GetSolgoVersion(),
		CompilerVersion:      descriptor.GetCompilerVersion(),
		ExecutionBytecode:    descriptor.GetExecutionBytecode(),
		Bytecode:             descriptor.GetDeployedBytecode(),
		/*
			Metadata:             descriptor.GetMetadata().ToProto(),
			Constructor:          descriptor.GetConstructor(),*/
		SafetyState:          utils.UnknownSafetyState, // TODO
		SourceAvailable:      descriptor.HasSources(),
		SelfDestructed:       d.SelfDestructed,
		ProxyImplementations: descriptor.Implementations,
		CompletedStates:      d.GetCompletedStates(),
		FailedStates:         d.GetFailedStates(),
		Partial:              len(d.GetFailedStates()) > 0,
		Processed:            d.Processed,
		CreatedAt:            time.Now().UTC(),
	}

	if d.GetContractModel() != nil {
		toReturn.CreatedAt = d.GetContractModel().CreatedAt
		toReturn.Id = d.GetContractModel().Id
		toReturn.UpdatedAt = time.Now().UTC()
	}

	return toReturn
}
