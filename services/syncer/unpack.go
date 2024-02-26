package syncer

import (
	"context"
	"fmt"
	"github.com/ethereum/go-ethereum/common"
	"github.com/unpackdev/downloader/pkg/entries"
	"github.com/unpackdev/downloader/pkg/machine"
	"github.com/unpackdev/downloader/pkg/options"
	"github.com/unpackdev/downloader/pkg/unpacker"
	"github.com/unpackdev/solgo/contracts"
	"github.com/unpackdev/solgo/utils"
	"github.com/urfave/cli/v2"
	"go.uber.org/zap"
	"time"
)

// Unpack ...
// @TODO: Implement UnpackFromEntry here with custom Entry... Should reuse code.
func (s *Service) Unpack(ctx *cli.Context) error {
	if !common.IsHexAddress(ctx.String("addr")) {
		return fmt.Errorf(
			"invalid ethereum hex address provided: %s", ctx.String("addr"),
		)
	}

	addr := common.HexToAddress(ctx.String("addr"))

	network, err := utils.GetNetworkFromString(ctx.String("network"))
	if err != nil {
		return fmt.Errorf(
			"failure to discover provided network '%s'", ctx.String("network"),
		)
	}

	networkId := utils.GetNetworkID(network)

	// First we need to initialize new contract instance. Reason why this is done prior to unpacking is because
	// we need to know block and transaction information. As well, no need to unpack the contract if one is not actual contract
	// or is being destroyed.
	contract, err := contracts.NewContract(
		ctx.Context, network, s.pool, nil, nil, nil, nil,
		s.etherscan, nil, s.bindManager, nil, nil, addr,
	)
	if err != nil {
		return err
	}

	entry := &entries.Entry{
		Network:      network,
		NetworkID:    networkId,
		ContractAddr: addr,
	}

	if entry.Header == nil || entry.Tx == nil || entry.Receipt == nil {
		if err := contract.DiscoverChainInfo(ctx.Context, options.G().Unpacker.OtsEnabled); err != nil {
			return err
		}
	} else {
		contract.SetBlock(entry.Header)
		contract.SetTransaction(entry.Tx)
		contract.SetReceipt(entry.Receipt)
	}

	// Basically, SolGo AST parser can panic in time to time...
	// What we want here is to capture these events and as well to report them as critical later on
	// with grafana/prom/loki being up...
	defer func(cloneEntry *entries.Entry) {
		if r := recover(); r != nil {
			zap.L().Error(
				"Recovered from panic in contract unpacking process...",
				zap.Any("panic", r),
				zap.Any("network", cloneEntry.Network),
				zap.Any("contract_address", cloneEntry.ContractAddr),
				zap.Uint64("contract_block_number", cloneEntry.Header.Number.Uint64()),
				zap.String("contract_tx_hash", cloneEntry.Tx.Hash().Hex()),
			)
		}
	}(entry)

	// Making sure we don't hang forever in case of hard unpack hangs...
	uctx, cancel := context.WithTimeout(ctx.Context, 30*time.Second)
	defer cancel()

	_, err = s.unpacker.Unpack(uctx, entry.GetDescriptor(s.unpacker, contract), unpacker.DiscoverState)
	if err != nil {
		return err
	}

	return nil
}

func (s *Service) UnpackFromEntry(ctx context.Context, entry *entries.Entry, state machine.State) (*unpacker.Descriptor, error) {
	// Basically, SolGo AST parser can panic in time to time...
	// What we want here is to capture these events and as well to report them as critical later on
	// with grafana/prom/loki being up...
	defer func(cloneEntry *entries.Entry) {
		if r := recover(); r != nil {
			zap.L().Error(
				"Recovered from panic in contract unpacking process...",
				zap.Any("panic", r),
				zap.Any("network", cloneEntry.Network),
				zap.Any("contract_address", cloneEntry.ContractAddr),
				zap.Uint64("contract_block_number", cloneEntry.Header.Number.Uint64()),
				zap.String("contract_tx_hash", cloneEntry.Tx.Hash().Hex()),
			)
		}
	}(entry)

	// First we need to initialize new contract instance. Reason why this is done prior to unpacking is because
	// we need to know block and transaction information. As well, no need to unpack the contract if one is not actual contract
	// or is being destroyed.
	contract, err := contracts.NewContract(
		ctx, entry.Network, s.pool, nil, nil, nil, nil,
		s.etherscan, nil, s.bindManager, nil, nil, entry.ContractAddr,
	)
	if err != nil {
		return nil, err
	}

	if entry.Header == nil || entry.Tx == nil || entry.Receipt == nil {
		if err := contract.DiscoverChainInfo(ctx, options.G().Unpacker.OtsEnabled); err != nil {
			return nil, err
		}
	} else {
		contract.SetBlock(entry.Header)
		contract.SetTransaction(entry.Tx)
		contract.SetReceipt(entry.Receipt)
	}

	descriptor, err := s.unpacker.Unpack(ctx, entry.GetDescriptor(s.unpacker, contract), state)
	if err != nil {
		return nil, err
	}

	return descriptor, nil
}
