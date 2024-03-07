package events

import (
	"encoding/json"
	"github.com/ethereum/go-ethereum/common"
)

type Unpack struct {
	CorrelationID string         `json:"correlation_id"`
	NetworkId     int64          `json:"network_id"`
	Address       common.Address `json:"address"`
	Resolved      bool           `json:"resolved"`
}

func (e *Unpack) MarshalBinary() ([]byte, error) {
	return json.Marshal(e)
}

// UnmarshalUnpack unmarshal a JSON byte slice into an Unpack instance.
func UnmarshalUnpack(data []byte) (*Unpack, error) {
	var u Unpack
	if err := json.Unmarshal(data, &u); err != nil {
		return nil, err
	}
	return &u, nil
}
