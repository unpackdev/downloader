package options

type Pprof struct {
	Enabled bool   `yaml:"enabled"`
	Addr    string `yaml:"addr"`
}
