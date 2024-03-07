package options

import (
	"fmt"
)

type Subscriber struct {
	Enabled          bool   `yaml:"enabled"`
	SubjectName      string `yaml:"subjectName"`
	Network          string `yaml:"network"`
	Resumption       bool   `yaml:"resumption"`
	Type             string `yaml:"type"`
	StartBlockNumber int    `yaml:"startBlockNumber"`
	EndBlockNumber   int    `yaml:"endBlockNumber"`
}

func (s *Subscriber) Validate() error {
	return nil
}

type Syncer struct {
	Subscribers []Subscriber `yaml:"subscribers"`
}

func (s *Syncer) GetByType(t string) (*Subscriber, error) {
	for _, sub := range s.Subscribers {
		if sub.Type == t {
			return &sub, nil
		}
	}

	return nil, fmt.Errorf(
		"failure to discover syncer subscriber by type: %s", t,
	)
}
