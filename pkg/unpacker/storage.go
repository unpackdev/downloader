package unpacker

import (
	"fmt"
	"github.com/unpackdev/inspector/pkg/models"
	"path/filepath"
	"strings"
	"time"
)

func (d *Descriptor) GetStorageCachePath() string {
	return filepath.Join(
		fmt.Sprintf("_%s", d.Network.String()),
		"mainnet", // This is hardcoded for now... Not sure if I personally ever want to support testnet
		"contracts",
		d.Header.Number.String(),
		d.Addr.Hex(),
	)
}

func (d *Descriptor) GetContractEntry() *models.Contract {
	descriptor := d.GetContract().GetDescriptor()

	toReturn := &models.Contract{
		NetworkId:   d.NetworkID.ToBig(),
		BlockNumber: d.Header.Number,
		//BlockHash:            d.Header.Hash(),
		TransactionHash: d.Tx.Hash(),
		Address:         d.Addr,
		//Proxy:                descriptor.Proxy,
		//ImplementationAddrs:  descriptor.Implementations,
		Name:             descriptor.GetName(),
		License:          descriptor.GetLicense(),
		Optimized:        descriptor.IsOptimized(),
		OptimizationRuns: descriptor.GetOptimizationRuns(),
		ABI:              descriptor.GetABI(),
		//SourcesProvider:      descriptor.GetSourcesProvider(),
		Verified:             descriptor.IsVerified(),
		VerificationProvider: descriptor.GetVerificationProvider(),
		EVMVersion:           strings.ToLower(descriptor.GetEVMVersion()),
		SolgoVersion:         descriptor.GetSolgoVersion(),
		CompilerVersion:      descriptor.CompilerVersion,
		/*		CreationBytecode:     descriptor.GetRuntimeBytecode(),
				DeployedBytecode:     descriptor.GetDeployedBytecode(),
				Metadata:             descriptor.GetMetadata().ToProto(),
				Constructor:          descriptor.GetConstructor(),*/
		CreatedAt: time.Now().UTC(),
	}

	if d.GetContractModel() != nil {
		toReturn.CreatedAt = d.GetContractModel().CreatedAt
		toReturn.Id = d.GetContractModel().Id
		toReturn.UpdatedAt = time.Now().UTC()
	}

	return toReturn
}
