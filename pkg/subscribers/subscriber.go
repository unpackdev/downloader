package subscribers

// Subscriber is an interface that defines the basic lifecycle and status operations
// for a subscription. Implementations of this interface can be used to start and stop
// subscriptions and to query their current status.
type Subscriber interface {
	// Start initiates the subscription process. It should establish any necessary
	// connections or routines needed for the subscription to function. Start should
	// return an error if the subscription fails to initiate properly.
	Start() error

	// Stop terminates the subscription. It should cleanly close any connections
	// and halt any routines associated with the subscription. Stop should ensure
	// that all resources are released properly. It should return an error if the
	// subscription fails to stop cleanly.
	Stop() error

	// Status returns the current status of the subscription. The status indicates
	// whether the subscription is active, inactive, or in any other state as defined
	// by the Status type. This method allows for querying the operational state of
	// the subscription at any time.
	Status() Status
}
