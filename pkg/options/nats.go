package options

type Queue struct {
	Name          string `yaml:"name"`
	Subject       string `yaml:"subject"`
	DeliveryGroup string `yaml:"deliveryGroup"`
}

type Nats struct {
	Enabled bool    `yaml:"enabled"`
	Addr    string  `yaml:"addr"`
	Queues  []Queue `yaml:"queues"`
}

func (n *Nats) GetQueueByName(name string) (*Queue, bool) {
	for _, queue := range n.Queues {
		if queue.Name == name {
			return &queue, true
		}
	}

	return nil, false
}
