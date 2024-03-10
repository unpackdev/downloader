package graph

import (
	"context"
	"fmt"
	"github.com/ethereum/go-ethereum/common"
	"github.com/unpackdev/inspector/pkg/events"
	"time"
)

func (r *mutationResolver) unpack(ctx context.Context, contract ContractUnpackRequest) (*Contract, error) {

	// Subscribing to the subject where the response is a specific request, in this case
	// we're pushing new unpack request to the service that in async mode unpacks the contract...
	correlationId := fmt.Sprintf("unpack.response.%d.%s", contract.NetworkID, contract.Address)

	eventRequestData := events.Unpack{
		CorrelationID: correlationId,
		NetworkId:     int64(contract.NetworkID),
		Address:       common.HexToAddress(contract.Address),
	}

	// Attempt to resolve from database prior we go into unpacking mode...
	contractDb, err := r.resolveContract(ctx, eventRequestData.NetworkId, eventRequestData.Address)
	if err == nil {
		if contractDb.Completed && !contractDb.Partial {
			return contractDb, nil
		}
	}

	sub, err := r.Nats.SubscribeSync(correlationId)
	if err != nil {
		return nil, fmt.Errorf(
			"failure to subscribe to correlation subject: %s", err,
		)
	}
	defer sub.Unsubscribe()

	dataBytes, err := eventRequestData.MarshalBinary()
	if err != nil {
		return nil, fmt.Errorf(
			"failure to marshal unpack event: %s", err,
		)
	}

	if err := r.Nats.Publish("contracts:unpack", dataBytes); err != nil {
		return nil, fmt.Errorf(
			"failure to publish unpack event: %s", err,
		)
	}

	msg, err := sub.NextMsg(30 * time.Second)
	if err != nil {
		return nil, fmt.Errorf(
			"timed out while waiting for unpack response for network: %d - address: %s",
			contract.NetworkID,
			contract.Address,
		)
	}

	event, err := events.UnmarshalUnpack(msg.Data)
	if err != nil {
		return nil, fmt.Errorf(
			"failure to decode response event for network: %d - address: %s",
			contract.NetworkID,
			contract.Address,
		)
	}

	if !event.Resolved {
		return nil, fmt.Errorf(
			"failure to resolve contract network: %d - address: %s",
			contract.NetworkID,
			contract.Address,
		)
	}

	return r.resolveContract(ctx, event.NetworkId, event.Address)
}
