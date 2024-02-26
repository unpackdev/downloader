package logger

import (
	"fmt"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

// GetProductionLogger creates and returns a new zap.Logger configured for production use.
// The production logger is optimized for performance. It uses a JSON encoder, logs to standard
// error, and writes at InfoLevel and above.
//
// Returns:
//
//	*zap.Logger - The configured zap.Logger for production use.
//	error       - An error if the logger could not be created.
func GetProductionLogger(level zap.AtomicLevel) (*zap.Logger, error) {
	config := zap.NewProductionConfig()
	config.Level = level
	logger, err := config.Build()
	return logger, err
}

// GetDevelopmentLogger creates and returns a new zap.Logger configured for development use.
// The development logger is more verbose and is intended for use during development. It uses
// a console encoder with colored level output and logs at the specified log level.
//
// Parameters:
//
//	level - The minimum logging level at which logs should be written,
//	        e.g., zapcore.DebugLevel, zapcore.InfoLevel.
//
// Returns:
//
//	*zap.Logger - The configured zap.Logger for development use.
//	error       - An error if the logger could not be created.
func GetDevelopmentLogger(level zap.AtomicLevel) (*zap.Logger, error) {
	config := zap.NewDevelopmentConfig()
	config.Level = level
	config.EncoderConfig.EncodeLevel = zapcore.CapitalColorLevelEncoder
	logger, err := config.Build()
	return logger, err
}

func GetLogger(env string, level string) (*zap.Logger, error) {
	configLevel, err := zap.ParseAtomicLevel(level)
	if err != nil {
		return nil, fmt.Errorf(
			"invalid logger level provided: %s - err: %s",
			level, err,
		)
	}

	switch env {
	case "development":
		return GetDevelopmentLogger(configLevel)
	case "production":
		return GetProductionLogger(configLevel)
	default:
		return nil, fmt.Errorf("failure to construct logger for env: %s", env)
	}
}
