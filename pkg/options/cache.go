package options

import "time"

type Cache struct {
	Addr            string        `yaml:"addr" json:"addr"`
	Password        string        `yaml:"password" json:"password"`
	DB              int           `yaml:"db" json:"db"`
	MaxRetries      int           `yaml:"maxRetries" json:"maxRetries"`
	MinRetryBackoff time.Duration `yaml:"minRetryBackoff" json:"minRetryBackoff"`
	MaxRetryBackoff time.Duration `yaml:"maxRetryBackoff" json:"maxRetryBackoff"`
	DialTimeout     time.Duration `yaml:"dialTimeout" json:"dialTimeout"`
	ReadTimeout     time.Duration `yaml:"readTimeout" json:"readTimeout"`
	WriteTimeout    time.Duration `yaml:"writeTimeout" json:"writeTimeout"`
}
