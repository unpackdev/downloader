package options

type Cors struct {
	Debug              bool     `yaml:"debug"`
	MaxAge             int      `yaml:"maxAge"`
	AllowCredentials   bool     `yaml:"allowCredentials"`
	OptionsPassthrough bool     `yaml:"optionsPassthrough"`
	AllowedOrigins     []string `yaml:"allowedOrigins"`
	AllowedMethods     []string `yaml:"allowedMethods"`
	AllowedHeaders     []string `yaml:"allowedHeaders"`
	ExposedHeaders     []string `yaml:"exposedHeaders"`
}
