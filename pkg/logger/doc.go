// Package logger provides a simplified interface for creating and configuring loggers
// using the Uber's zap logging library. It includes functions to create both production
// and development loggers with appropriate configurations.
//
// The production logger is optimized for performance and is suitable for use in
// a production environment. The development logger, on the other hand, provides
// more verbose output and is intended for use during the development process.
//
// Additionally, provides a simple and convenient wrapper around the zap logging
// library. It offers structured logging capabilities across various log levels,
// including fatal, error, warning, info, and debug.
package logger
