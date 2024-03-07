package types

import (
	"database/sql/driver"
	"github.com/unpackdev/solgo/standards"
	"github.com/unpackdev/solgo/utils"
)

type Standards []standards.Standard

// Scan implements the sql.Scanner interface.
// This method will be called by the database/sql package when scanning a column value into the Standards.
func (s *Standards) Scan(value interface{}) error {
	return utils.FromJSON([]byte(value.(string)), s)
}

// Value implements the driver.Valuer interface.
// This method will be called by the database/sql package when storing a Standards value in a column.
func (s *Standards) Value() (driver.Value, error) {
	value, err := utils.ToJSON(s)
	return string(value), err
}

func (s *Standards) StringArray() []string {
	toReturn := []string{}
	for _, standard := range *s {
		toReturn = append(toReturn, standard.String())
	}

	return toReturn
}
