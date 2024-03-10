package options

type Rpc struct {
	Enabled bool   `yaml:"enabled"`
	Addr    string `yaml:"addr"`
}
