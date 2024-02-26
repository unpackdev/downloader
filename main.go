package main

import (
	"context"
	"fmt"
	"github.com/unpackdev/downloader/cmd"
	app "github.com/unpackdev/downloader/pkg/app"
	"github.com/unpackdev/downloader/pkg/logger"
	"github.com/unpackdev/downloader/pkg/options"
	"os"

	"github.com/urfave/cli/v2"
	"go.uber.org/zap"
)

var (
	// Version derived from build tags -ldflags "-X main.Version=x.x.x"
	Version string
)

func main() {

	// Let's figure out options, extract them, set them under global scope and
	// move along with application...
	optsFiles := os.Getenv("DOWNLOADER_OPTIONS_PATH")
	if len(optsFiles) < 1 {
		panic("Options path is not set. You need to set `DOWNLOADER_OPTIONS_PATH` environment variable")
	}

	opts, err := options.NewDefaultOptions(options.PathToSlice(optsFiles))
	if err != nil {
		panic(err)
	}
	options.SetGlobalOptions(opts)

	zlog, err := logger.GetLogger(opts.Logger.Env, opts.Logger.Level)
	if err != nil {
		panic(err)
	}
	zap.ReplaceGlobals(zlog)

	cli.VersionPrinter = func(cCtx *cli.Context) {
		fmt.Printf("version=%s revision=%s\n", cCtx.App.Version, "%s")
	}

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	baseApp, _ := app.New(ctx, app.Descriptor{
		Name:        "(Un)Pack Downloader",
		Usage:       "Ethereum Smart Contracts Downloader and Storage Manager",
		Version:     fmt.Sprintf("v%s", Version),
		HelpName:    "downloader",
		Description: `Ethereum Smart Contracts Downloader and Storage Manager`,
	})

	for registry, commands := range cmd.GetCommands() {
		if err := baseApp.RegisterCommands(commands); err != nil {
			zap.L().Error(
				"failure to register application commands",
				zap.String("registry", registry),
				zap.Error(err),
			)
			os.Exit(1)
		}
	}

	if err := baseApp.Run(os.Args); err != nil {
		zlog.Fatal("failed to run downloader app", zap.Error(err))
	}
}
