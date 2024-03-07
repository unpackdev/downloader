package types

import (
	"database/sql/driver"
	"github.com/ethereum/go-ethereum/common"
)

type Hash struct {
	common.Hash
}

func NewHash(h common.Hash) Hash {
	return Hash{Hash: h}
}

// Scan implements the sql.Scanner interface.
// This method will be called by the database/sql package when scanning a column value into the Standards.
func (s *Hash) Scan(value interface{}) error {
	s.Hash = common.HexToHash(value.(string))
	return nil
}

// Value implements the driver.Valuer interface.
// This method will be called by the database/sql package when storing a Standards value in a column.
func (s *Hash) Value() (driver.Value, error) {
	return s.Hex(), nil
}
