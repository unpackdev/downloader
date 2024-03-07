package types

import (
	"database/sql/driver"
	"github.com/ethereum/go-ethereum/common"
)

type Bytecode []byte

// Scan implements the sql.Scanner interface.
// This method will be called by the database/sql package when scanning a column value into the Standards.
func (s *Bytecode) Scan(value interface{}) error {
	*s = common.Hex2Bytes(value.(string))
	return nil
}

// Value implements the driver.Valuer interface.
// This method will be called by the database/sql package when storing a Standards value in a column.
func (s *Bytecode) Value() (driver.Value, error) {
	return common.Bytes2Hex(*s), nil
}
