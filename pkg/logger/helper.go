package logger

import "go.uber.org/zap"

// Fatal logs a message at the fatal level including any additional fields provided.
// The logger then calls os.Exit(1), terminating the program.
// Use this level for errors that should not occur during normal operation and indicate
// a severe problem that requires immediate attention.
//
// Parameters:
//
//	message - The log message to be written.
//	err     - The error object associated with this log message.
//	fields  - Optional zap fields for additional structured context.
func Fatal(message string, err error, fields ...zap.Field) {
	zap.L().Fatal(message, append(fields, zap.Error(err))...)
}

// Error logs a message at the error level including any additional fields provided.
// This level is used for logging errors that have occurred during execution.
// These errors might require attention but do not necessarily indicate an immediate
// failure of the entire application.
//
// Parameters:
//
//	message - The log message to be written.
//	err     - The error object associated with this log message.
//	fields  - Optional zap fields for additional structured context.
func Error(message string, err error, fields ...zap.Field) {
	zap.L().Error(message, append(fields, zap.Error(err))...)
}

// Warn logs a message at the warning level including any additional fields provided.
// This level is used for potentially harmful situations that warrant attention
// but do not represent immediate errors.
//
// Parameters:
//
//	message - The log message to be written.
//	fields  - Optional zap fields for additional structured context.
func Warn(message string, fields ...zap.Field) {
	zap.L().Warn(message, fields...)
}

// Info logs a message at the info level including any additional fields provided.
// Use this level for informational messages that highlight the progress of the application
// under normal circumstances.
//
// Parameters:
//
//	message - The log message to be written.
//	fields  - Optional zap fields for additional structured context.
func Info(message string, fields ...zap.Field) {
	zap.L().Info(message, fields...)
}

// Debug logs a message at the debug level including any additional fields provided.
// This level is used for detailed informational messages that are useful for debugging
// an application. These messages are typically voluminous and are not required in
// a production environment.
//
// Parameters:
//
//	message - The log message to be written.
//	fields  - Optional zap fields for additional structured context.
func Debug(message string, fields ...zap.Field) {
	zap.L().Debug(message, fields...)
}
