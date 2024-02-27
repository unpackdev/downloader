// Package subscribers provides a comprehensive solution for managing subscriptions
// to Ethereum blockchain events. It supports both real-time monitoring of head block
// updates and detailed analysis of historical blockchain data through archive blocks.
// The package facilitates executing custom logic, known as hooks, in response to
// these events, enabling users to perform real-time actions or process historical
// data efficiently. It offers a robust framework for the registration, unregistration,
// and concurrent-safe notification of subscribers, along with foundational types and
// interfaces for categorization and state management of subscribers within a system.
// This dual focus on both live and archival blockchain data, combined with the package's
// flexible subscriber management infrastructure, makes it a versatile tool for
// applications requiring detailed blockchain event handling and processing.
package subscribers
