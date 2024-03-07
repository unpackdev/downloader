package types

import (
	"database/sql/driver"
	"github.com/ethereum/go-ethereum/common"
	"github.com/unpackdev/solgo/utils"
)

type Addresses []common.Address

// Scan implements the sql.Scanner interface.
// This method will be called by the database/sql package when scanning a column value into the Standards.
func (s *Addresses) Scan(value interface{}) error {
	return utils.FromJSON([]byte(value.(string)), s)
}

// Value implements the driver.Valuer interface.
// This method will be called by the database/sql package when storing a Standards value in a column.
func (s *Addresses) Value() (driver.Value, error) {
	value, err := utils.ToJSON(s)
	return string(value), err
}

func (s *Addresses) StringArray() []string {
	var toReturn []string
	for _, addr := range *s {
		toReturn = append(toReturn, addr.Hex())
	}
	return toReturn
}
