package unpacker

import (
	"context"
	"github.com/unpackdev/inspector/pkg/machine"
	"go.uber.org/zap"
	"strings"
)

type ProvidersContractHandler struct {
	ctx context.Context
	u   *Unpacker
}

func NewProvidersContractHandler(ctx context.Context, u *Unpacker) machine.Handler {
	bh := &ProvidersContractHandler{ctx: ctx, u: u}
	return machine.Handler{
		Enter:   bh.Enter,
		Process: bh.Process,
		Exit:    bh.Exit,
	}
}

func (dh *ProvidersContractHandler) Enter(data machine.Data) (machine.Data, error) {
	return data, nil
}

func (dh *ProvidersContractHandler) Process(data machine.Data) (machine.State, machine.Data, error) {
	descriptor := toDescriptor(data)

	// First we are going to check if dependency states are completed.
	if !descriptor.HasCompletedState(DiscoverState) {
		descriptor.SetNextState(MetadataState) // <- come back to this state afterward...
		return DiscoverState, descriptor, nil
	}

	contract := descriptor.GetContract()
	cdescriptor := contract.GetDescriptor()

	// We're now going to look through local source code cache.
	// This is a way of not going to any 3rd party discovery service and use locally what
	// we have. Unless it's partial. In that case, we want to ensure we use discovery again.
	if !cdescriptor.HasSources() {
		//dh.u.
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
		}

		/*		if !cdescriptor.HasSources() {
				sources, err := dh.u.downloader.Seek(dh.ctx, descriptor.GetNetwork(), cdescriptor.GetBlock().Number(), cdescriptor.GetName(), descriptor.GetAddress())
				if err == nil {
					contract.GetDescriptor().Sources = sources
					descriptor.sources = sources

					// In case that we didn't initially have sources and now we have...
					descriptor.RemoveFailedState(SourceProvidersState)
				}
			}*/

	}

	if !descriptor.HasFailedState(SourceProvidersState) {
		descriptor.AppendCompletedState(SourceProvidersState)
	}

	/*	fmt.Println("Here...")
		os.Exit(1)
		return DoneState, descriptor, nil*/

	return SourcesState, descriptor, nil
}

func (dh *ProvidersContractHandler) Exit(data machine.Data) (machine.Data, error) {
	return data, nil
}
