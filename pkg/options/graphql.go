package options

import "time"

type GraphQLCache struct {
	Adapter            string        `yaml:"adapter"`
	QueryCacheDuration time.Duration `yaml:"queryCacheDuration"`
}

type GraphQL struct {
	Transports []string     `yaml:"transports"`
	Addr       string       `yaml:"addr"`
	Cors       Cors         `yaml:"cors"`
	Cache      GraphQLCache `yaml:"cache"`
}

func (g *GraphQL) TransportEnabled(t string) bool {
	for _, tr := range g.Transports {
		if tr == t {
			return true
		}
	}

	return false
}
