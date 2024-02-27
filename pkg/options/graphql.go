package options

type GraphQL struct {
	Transports []string `yaml:"transports"`
	Addr       string   `yaml:"addr"`
	Cors       Cors     `yaml:"cors"`
}

func (g *GraphQL) TransportEnabled(t string) bool {
	for _, tr := range g.Transports {
		if tr == t {
			return true
		}
	}

	return false
}
