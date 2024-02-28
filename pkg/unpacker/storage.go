package unpacker

import (
	"fmt"
	"github.com/unpackdev/inspector/pkg/storage"
	"github.com/unpackdev/solgo/utils"
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

func (d *Descriptor) GetStorageEntry() *storage.Entry {
	descriptor := d.GetContract().GetDescriptor()
	return &storage.Entry{
		Path:                 d.GetStorageCachePath(),
		Network:              d.Network,
		NetworkID:            d.NetworkID,
		BlockNumber:          d.Header.Number,
		BlockHash:            d.Header.Hash(),
		TransactionHash:      d.Tx.Hash(),
		Address:              d.Addr,
		Proxy:                descriptor.Proxy,
		ImplementationAddrs:  descriptor.Implementations,
		Name:                 descriptor.GetName(),
		License:              descriptor.GetLicense(),
		Optimized:            descriptor.IsOptimized(),
		OptimizationRuns:     descriptor.GetOptimizationRuns(),
		ABI:                  descriptor.GetABI(),
		SourcesProvider:      descriptor.GetSourcesProvider(),
		Verified:             descriptor.IsVerified(),
		VerificationProvider: descriptor.GetVerificationProvider(),
		EVMVersion:           strings.ToLower(descriptor.GetEVMVersion()),
		SolgoVersion:         descriptor.GetSolgoVersion(),
		CompilerVersion:      utils.ParseSemanticVersion(descriptor.CompilerVersion),
		CreationBytecode:     descriptor.GetRuntimeBytecode(),
		DeployedBytecode:     descriptor.GetDeployedBytecode(),
		Metadata:             descriptor.GetMetadata().ToProto(),
		Constructor:          descriptor.GetConstructor(),
		InsertedAt:           time.Now().UTC(),
	}
}
