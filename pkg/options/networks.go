package options

import "fmt"

type Network struct {
	Name          string `yaml:"name"`
	NetworkId     int    `yaml:"networkId"`
	CanonicalName string `yaml:"canonicalName"`
	Symbol        string `yaml:"symbol"`
	Website       string `yaml:"website"`
	Suspended     bool   `yaml:"suspended"`
	Maintenance   bool   `yaml:"maintenance"`
}

func (o *Options) GetNetworkById(id uint64) (*Network, error) {
	for _, network := range o.Networks {
		if network.NetworkId == int(id) {
			return &network, nil
		}
	}

	return nil, fmt.Errorf("failure to discover network by id '%d'", id)
}
