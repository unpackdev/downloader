package unpacker

import (
	"context"
	"github.com/unpackdev/inspector/pkg/machine"
	"github.com/unpackdev/inspector/pkg/options"
	"github.com/unpackdev/solgo"
	"go.uber.org/zap"
	"path/filepath"
	"strings"
)

// ProvidersContractHandler manages the lifecycle and state transitions
// of smart contracts within the unpacker process. It interfaces with
// the blockchain network to discover and validate contract source code
// and metadata, leveraging local caches and external services as necessary.
type ProvidersContractHandler struct {
	ctx context.Context
	u   *Unpacker
}

// NewProvidersContractHandler initializes a new instance of ProvidersContractHandler
// with a given context and an Unpacker reference. It returns a machine.Handler
// configured with the necessary callbacks for state transitions.
func NewProvidersContractHandler(ctx context.Context, u *Unpacker) machine.Handler {
	bh := &ProvidersContractHandler{ctx: ctx, u: u}
	return machine.Handler{
		Enter:   bh.Enter,
		Process: bh.Process,
		Exit:    bh.Exit,
	}
}

// Enter is called when the ProvidersContractHandler enters a new state.
// It currently performs no operations and immediately returns the input data unmodified.
func (dh *ProvidersContractHandler) Enter(data machine.Data) (machine.Data, error) {
	return data, nil
}

// Process handles the core logic of the ProvidersContractHandler during its active state.
// It performs several checks and operations:
// - Verifies if dependency states are completed.
// - Attempts to load contract source code from a local cache.
// - Falls back to discovering source code from external services if not available locally.
// - Logs errors and updates the contract descriptor with the discovered sources.
func (dh *ProvidersContractHandler) Process(data machine.Data) (machine.State, machine.Data, error) {
	descriptor := toDescriptor(data)

	// First we are going to check if dependency states are completed.
	if !descriptor.HasCompletedState(DiscoverState) {
		descriptor.SetNextState(MetadataState) // <- come back to this state afterward...
		return DiscoverState, descriptor, nil
	}

	contract := descriptor.GetContract()
	cdescriptor := contract.GetDescriptor()
	cmodel := descriptor.GetContractModel()

	// We're now going to look through local source code cache.
	// This is a way of not going to any 3rd party discovery service and use locally what we have.
	// In case that we have sources but do not have name for example, treating it as we don't have anything...
	if !cdescriptor.HasSources() && cmodel != nil && cmodel.SourceAvailable && len(cmodel.Name) != 0 {
		sourcesPath := filepath.Join(
			options.G().Storage.ContractsPath,
			descriptor.GetStorageCachePath(),
		)

		sources, err := solgo.NewSourcesFromPath(cmodel.Name, sourcesPath)
		if err != nil {
			zap.L().Error(
				"failed to load local source code for contract",
				zap.Error(err),
				zap.String("network", descriptor.GetNetwork().String()),
				zap.Any("network_id", descriptor.GetNetworkID()),
				zap.String("contract_address", descriptor.GetAddr().Hex()),
				zap.Uint64("block_number", descriptor.GetHeader().Number.Uint64()),
				zap.String("transaction_hash", descriptor.GetTransaction().Hash().Hex()),
			)
		} else {
			cdescriptor.Sources = sources
			cdescriptor.Name = cmodel.Name
			cdescriptor.License = cmodel.License
			cdescriptor.Proxy = cmodel.Proxy
			cdescriptor.SourcesProvider = cmodel.SourcesProvider
			cdescriptor.CompilerVersion = cmodel.CompilerVersion
			cdescriptor.SolgoVersion = cmodel.SolgoVersion
			cdescriptor.Implementations = cmodel.ProxyImplementations
			cdescriptor.Optimized = cmodel.Optimized
			cdescriptor.OptimizationRuns = cmodel.OptimizationRuns
			cdescriptor.EVMVersion = cmodel.EVMVersion
			cdescriptor.ABI = cmodel.ABI
			cdescriptor.Verified = cmodel.Verified
			cdescriptor.VerificationProvider = cmodel.VerificationProvider

			// In case that we didn't initially have sources, and now we have...
			descriptor.RemoveFailedState(SourceProvidersState)
		}
	}

	if !cdescriptor.HasSources() {
		if err := contract.DiscoverSourceCode(dh.ctx); err != nil {
			if !strings.Contains(err.Error(), "contract source code not verified") {
				zap.L().Error(
					"failed to discover source code for contract",
					zap.Error(err),
					zap.String("network", descriptor.GetNetwork().String()),
					zap.Any("network_id", descriptor.GetNetworkID()),
					zap.String("contract_address", descriptor.GetAddr().Hex()),
					zap.Uint64("block_number", descriptor.GetHeader().Number.Uint64()),
					zap.String("transaction_hash", descriptor.GetTransaction().Hash().Hex()),
					zap.String("source_provider", cdescriptor.GetSourcesProvider()),
				)
			}
		} else {
			// In case that we didn't initially have sources, and now we have...
			descriptor.RemoveFailedState(SourceProvidersState)
		}
	}

	if !descriptor.HasFailedState(SourceProvidersState) {
		descriptor.AppendCompletedState(SourceProvidersState)
	}

	return SourcesState, descriptor, nil
}

// Exit is called when the ProvidersContractHandler exits its current state.
// It currently performs no operations and immediately returns the input data unmodified.
func (dh *ProvidersContractHandler) Exit(data machine.Data) (machine.Data, error) {
	return data, nil
}
