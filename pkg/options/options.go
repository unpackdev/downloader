package options

import (
	"fmt"
	"github.com/cristalhq/aconfig"
	"github.com/cristalhq/aconfig/aconfigdotenv"
	"github.com/cristalhq/aconfig/aconfigyaml"
	"github.com/unpackdev/solgo/clients"
	"strings"
)

var (
	options *Options
)

// Logger defines the configuration for logging.
// It includes environment and logging level settings.
type Logger struct {
	Env   string `yaml:"env" json:"env"`     // Env specifies the environment (e.g., "production", "development").
	Level string `yaml:"level" json:"level"` // Level defines the logging level (e.g., "info", "debug").
}

// Options contains all the configuration options for the downloader application.
// It includes settings for logger and other components of the application.
type Options struct {
	OptionsPath      string         `default:"~/.unpack/options.yaml" env:"DOWNLOADER_OPTIONS_PATH"` // OptionsPath defines the path to the configuration file.
	Logger           Logger         `yaml:"logger" json:"logger"`                                    // Logger specifies the logging configuration.
	*clients.Options `yaml:"nodes"` // Options embeds the client options.
	Db               Db             // Database options.
	Nats             Nats           // Nats client and queues options.
}

// NewDefaultOptions creates a new Options object with the given configuration paths.
// It loads the configuration from the specified paths and handles any errors encountered
// during the loading process. Returns an error if loading fails.
func NewDefaultOptions(paths []string) (*Options, error) {
	var opts Options
	loader := aconfig.LoaderFor(&opts, aconfig.Config{
		AllowUnknownEnvs:   false,
		AllowUnknownFields: false,
		EnvPrefix:          "DOWNLOADER_",
		FlagPrefix:         "downloader",
		Files:              paths,
		FileDecoders: map[string]aconfig.FileDecoder{
			".yaml": aconfigyaml.New(),
			"env":   aconfigdotenv.New(),
		},
	})

	if err := loader.Load(); err != nil {
		return nil, fmt.Errorf(
			"failure to load default application options: %s", err,
		)
	}

	return &opts, nil
}

// Validate goes through the validation of the provided options
// @TODO: Fix this in the future...
func (o *Options) Validate() error {
	return nil
}

// PathToSlice converts a comma-separated string of paths into a slice of strings.
// Each path is trimmed of any leading and trailing whitespace characters.
func PathToSlice(path string) []string {
	pathsRaw := strings.Split(path, ",")
	var toReturn []string
	for _, p := range pathsRaw {
		toReturn = append(toReturn, strings.Trim(p, ""))
	}
	return toReturn
}

// SetGlobalOptions sets the provided Options object as the global options.
// This function is usually called after initializing the options to make them
// accessible throughout the application.
func SetGlobalOptions(opt *Options) {
	options = opt
}

// G returns the global Options object set by SetGlobalOptions.
// It provides a convenient way to access application-wide configurations.
func G() *Options {
	return options
}
