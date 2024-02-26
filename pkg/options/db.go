package options

type Db struct {
	Path           string `yaml:"path"`
	FlattenWorkers int    `yaml:"flattenWorkers"`
}
