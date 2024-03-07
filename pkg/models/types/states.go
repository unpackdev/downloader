package types

import (
	"database/sql/driver"
	"github.com/unpackdev/inspector/pkg/machine"
	"github.com/unpackdev/solgo/utils"
)

type States []machine.State

// Scan implements the sql.Scanner interface.
// This method will be called by the database/sql package when scanning a column value into the Standards.
func (s *States) Scan(value interface{}) error {
	return utils.FromJSON([]byte(value.(string)), s)
}

// Value implements the driver.Valuer interface.
// This method will be called by the database/sql package when storing a Standards value in a column.
func (s *States) Value() (driver.Value, error) {
	value, err := utils.ToJSON(s)
	return string(value), err
}

func (s *States) StringArray() []string {
	toReturn := []string{}
	for _, state := range *s {
		toReturn = append(toReturn, state.String())
	}

	return toReturn
}
