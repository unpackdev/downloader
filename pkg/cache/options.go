package cache

import "time"

type Options struct {
	Addr            string        `mapstructure:"addr" yaml:"addr" json:"addr"`
	Password        string        `mapstructure:"password" yaml:"password" json:"password"`
	DB              int           `mapstructure:"db" yaml:"db" json:"db"`
	MaxRetries      int           `mapstructure:"max_retries" yaml:"max_retries" json:"max_retries"`
	MinRetryBackoff time.Duration `mapstructure:"min_retry_backoff" yaml:"min_retry_backoff" json:"min_retry_backoff"`
	MaxRetryBackoff time.Duration `mapstructure:"max_retry_backoff" yaml:"max_retry_backoff" json:"max_retry_backoff"`
	DialTimeout     time.Duration `mapstructure:"dial_timeout" yaml:"dial_timeout" json:"dial_timeout"`
	ReadTimeout     time.Duration `mapstructure:"read_timeout" yaml:"read_timeout" json:"read_timeout"`
	WriteTimeout    time.Duration `mapstructure:"write_timeout" yaml:"write_timeout" json:"write_timeout"`
}
