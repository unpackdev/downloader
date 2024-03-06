package options

type Unpacker struct {
	ForceReprocess bool `yaml:"forceReprocess"` // Reprocess all the contracts regardless of their local state
	OtsEnabled     bool `yaml:"otsEnabled"`
}
