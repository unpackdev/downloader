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

type Logger struct {
	Env   string `yaml:"env" json:"env"`
	Level string `yaml:"level" json:"level"`
}

type Options struct {
	OptionsPath      string `default:"~/.unpack/options.yaml" env:"DOWNLOADER_OPTIONS_PATH"`
	Logger           Logger `yaml:"logger" json:"logger"`
	*clients.Options `yaml:"nodes"`
}

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

func PathToSlice(path string) []string {
	pathsRaw := strings.Split(path, ",")
	var toReturn []string
	for _, p := range pathsRaw {
		toReturn = append(toReturn, strings.Trim(p, ""))
	}
	return toReturn
}

func SetGlobalOptions(opt *Options) {
	options = opt
}

func G() *Options {
	return options
}
