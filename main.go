package main

import (
	"fmt"
	"github.com/unpackdev/downloader/pkg/logger"
	"github.com/unpackdev/downloader/pkg/options"
	"os"

	"github.com/urfave/cli"
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

	var commands []cli.Command

	app := &cli.App{
		Name:        "(Un)Pack Downloader",
		Version:     fmt.Sprintf("v%s", Version),
		HelpName:    "downloader",
		Description: `Ethereum Smart Contracts Downloader and Storage Manager`,
		Usage:       "",
		Commands:    commands,
	}

	if err := app.Run(os.Args); err != nil {
		zlog.Fatal("failed to run downloader app", zap.Error(err))
	}
}
