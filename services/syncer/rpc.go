package syncer

import (
	"context"
	"fmt"
	"github.com/ethereum/go-ethereum/common"
	"github.com/unpackdev/inspector/pkg/entries"
	"github.com/unpackdev/inspector/pkg/options"
	"github.com/unpackdev/inspector/pkg/unpacker"
	contracts_pb "github.com/unpackdev/protos/dist/go/contracts"
	server_pb "github.com/unpackdev/protos/dist/go/server"
	"github.com/unpackdev/solgo/utils"
	"go.uber.org/zap"
	"google.golang.org/grpc"
	"net"
	"sync"
)

type Server struct {
	*Service
	ctx context.Context
	server_pb.UnimplementedUnpackServer
	processingContracts map[string]bool
	mu                  sync.Mutex
}

func NewGRPCServer(ctx context.Context, service *Service) (*Server, error) {
	return &Server{
		ctx:                 ctx,
		Service:             service,
		processingContracts: make(map[string]bool),
	}, nil
}

func (s *Server) Start() error {
	zap.L().Info(
		"Starting Syncer RPC server",
		zap.Bool("enabled", options.G().Rpc.Enabled),
		zap.String("addr", options.G().Rpc.Addr),
	)

	if !options.G().Rpc.Enabled {
		return nil
	}

	lis, err := net.Listen("tcp", options.G().Rpc.Addr)
	if err != nil {
		return fmt.Errorf("failure to listen (rpc): %w", err)
	}

	grpcServer := grpc.NewServer()
	server_pb.RegisterUnpackServer(grpcServer, s.rpc)

	if err := grpcServer.Serve(lis); err != nil {
		return fmt.Errorf("failed to serve (rpc): %w", err)
	}

	select {
	case <-s.ctx.Done():
		zap.L().Info("Shutting down Syncer RPC server")
		grpcServer.GracefulStop()
		return nil
	}
}

func (s *Server) Unpack(ctx context.Context, req *server_pb.UnpackRequest) (resp *server_pb.UnpackResponse, err error) {
	resp = &server_pb.UnpackResponse{
		Status:    true,
		NetworkId: req.GetNetworkId(),
		Contracts: make([]*server_pb.UnpackResponse_ContractQueueResponse, 0),
	}

	// Basically, SolGo AST parser can panic in time to time...
	// What we want here is to capture these events and as well to report them as critical later on
	// with grafana/prom/loki being up...
	defer func() {
		if r := recover(); r != nil {
			zap.L().Error(
				"Recovered from panic in contract unpacking process...",
				zap.Any("panic", r),
			)
		}
	}()

	for _, addrHex := range req.GetAddresses() {
		if !common.IsHexAddress(addrHex) {
			return nil, fmt.Errorf(
				"invalid ethereum hex address provided: %s", addrHex,
			)
		}

		networkId := utils.NetworkID(req.GetNetworkId())
		network, err := utils.GetNetworkFromID(networkId)
		if err != nil {
			return nil, err
		}

		entry := &entries.Entry{
			Network:      network,
			NetworkID:    networkId,
			ContractAddr: common.HexToAddress(addrHex),
		}

		descriptor, err := s.UnpackFromEntry(ctx, entry, unpacker.DiscoverState)
		if err != nil {
			return nil, err
		}

		contractResponse := &server_pb.UnpackResponse_ContractQueueResponse{
			Status: server_pb.UnpackResponse_ContractQueueResponse_CQR_UNKNOWN,
		}

		if descriptor.GetContract() != nil && descriptor.GetContract().GetDescriptor() != nil {
			contract := descriptor.GetContract()
			cdescriptor := contract.GetDescriptor()
			contractResponse.Status = server_pb.UnpackResponse_ContractQueueResponse_CQR_FOUND

			contractResponse.Contract = &contracts_pb.Contract{
				NetworkId:        networkId.ToBig().Int64(),
				Address:          addrHex,
				Name:             cdescriptor.GetName(),
				Abi:              cdescriptor.GetABI(),
				License:          cdescriptor.GetLicense(),
				CompilerVersion:  cdescriptor.GetCompilerVersion(),
				BlockNumber:      cdescriptor.GetBlock().Number.Int64(),
				BlockHash:        cdescriptor.GetBlock().Hash().Hex(),
				TransactionHash:  cdescriptor.GetTransaction().Hash().Hex(),
				Verified:         cdescriptor.IsVerified(),
				Optimized:        cdescriptor.IsOptimized(),
				IsProxy:          cdescriptor.Proxy,
				OptimizationRuns: int32(cdescriptor.GetOptimizationRuns()),
			}

			if cdescriptor.HasSources() {
				contractResponse.Contract.Sources = descriptor.GetContract().GetDescriptor().GetSources().ToProto()
			}
		}

		resp.Contracts = append(resp.Contracts, contractResponse)
	}

	return resp, nil
}
