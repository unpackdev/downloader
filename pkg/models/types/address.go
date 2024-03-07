package types

import (
	"database/sql/driver"
	"github.com/ethereum/go-ethereum/common"
)

type Address struct {
	common.Address
}

func NewAddress(h common.Address) Address {
	return Address{Address: h}
}

// Scan implements the sql.Scanner interface.
// This method will be called by the database/sql package when scanning a column value into the Standards.
func (s *Address) Scan(value interface{}) error {
	s.Address = common.HexToAddress(value.(string))
	return nil
}

// Value implements the driver.Valuer interface.
// This method will be called by the database/sql package when storing a Standards value in a column.
func (s *Address) Value() (driver.Value, error) {
	return s.Hex(), nil
}
