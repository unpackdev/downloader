package types

import (
	"database/sql/driver"
	"fmt"
	"math/big"
)

type BigInt struct {
	*big.Int
}

func NewBigInt(bi *big.Int) *BigInt {
	return &BigInt{Int: bi}
}

// Scan implements the sql.Scanner interface.
// This method will be called by the database/sql package when scanning a column value into BigInt.
func (bi *BigInt) Scan(value interface{}) error {
	bi.Int = new(big.Int)

	switch v := value.(type) {
	case int64:
		bi.SetInt64(v)
		return nil
	case uint64:
		bi.SetUint64(v)
		return nil
	case string:
		if _, ok := bi.SetString(v, 10); !ok {
			return fmt.Errorf("BigInt.Scan: invalid string")
		}
		return nil
	case []byte:
		str := string(v)
		if _, ok := bi.SetString(str, 10); !ok {
			return fmt.Errorf("BigInt.Scan: invalid byte slice")
		}
		return nil
	default:
		return fmt.Errorf("BigInt.Scan: unsupported type (%T)", value)
	}
}

// Value implements the driver.Valuer interface.
// This method will be called by the database/sql package when storing a BigInt value in a column.
func (bi *BigInt) Value() (driver.Value, error) {
	return bi, nil
}
