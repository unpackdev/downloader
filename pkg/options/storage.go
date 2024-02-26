package options

type Storage struct {
	Enabled       bool   `yaml:"enabled" json:"enabled"`
	ContractsPath string `yaml:"contractsPath" json:"contractsPath"`
	DatabasePath  string `yaml:"databasePath" json:"databasePath"`
}
