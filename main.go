package main

import (
	"fmt"
	"os"

	"github.com/urfave/cli"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

func main() {
	config := zap.NewDevelopmentConfig()
	config.Level = zap.NewAtomicLevelAt(zap.InfoLevel)
	config.EncoderConfig.EncodeLevel = zapcore.CapitalColorLevelEncoder
	logger, err := config.Build()
	if err != nil {
		panic(err)
	}
	zap.ReplaceGlobals(logger)

	cli.VersionPrinter = func(cCtx *cli.Context) {
		fmt.Printf("version=%s revision=%s\n", cCtx.App.Version, "%s")
	}

	var commands []cli.Command

	app := &cli.App{
		Name:        "(Un)Pack Downloader",
		Version:     "v0.1.0",
		HelpName:    "downloader",
		Description: `Ethereum Smart Contracts Downloader and Storage Manager`,
		Usage:       "",
		Commands:    commands,
	}

	if err := app.Run(os.Args); err != nil {
		logger.Fatal("failed to run downloader app", zap.Error(err))
	}
}
