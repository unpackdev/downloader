package options

type Network struct {
	Name          string `yaml:"name"`
	NetworkId     int    `yaml:"networkId"`
	CanonicalName string `yaml:"canonicalName"`
	Symbol        string `yaml:"symbol"`
	Website       string `yaml:"website"`
	Suspended     bool   `yaml:"suspended"`
	Maintenance   bool   `yaml:"maintenance"`
}
