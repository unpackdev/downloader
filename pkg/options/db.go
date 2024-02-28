package options

import "path/filepath"

type Db struct {
	Dialect      string `yaml:"dialect"`
	Datasource   string `yaml:"datasource"`
	MigrationDir string `yaml:"migrationDir"`
}

func (o *Options) GetSqliteDbPath() string {
	return filepath.Join(
		o.Storage.DatabasePath, o.Db.Datasource,
	)
}
