package subscribers

// SubscriberType is a string type that defines various categories or identifiers
// for subscribers. It is used to distinguish between different types of subscriptions
// within the system, enabling type-specific handling and management of subscribers.
type SubscriberType string

// String returns the string representation of the SubscriberType.
func (t SubscriberType) String() string {
	return string(t)
}

// Status is an enumerated type (int16) representing the operational state of a subscriber.
// It indicates whether a subscriber is currently active, inactive, or in any other defined state.
type Status int16

const (
	// StatusActive indicates that the subscriber is currently active and operational.
	// It is engaged in its subscription duties, such as listening for and processing events.
	StatusActive Status = iota

	// StatusNotActive indicates that the subscriber is not currently active. It may be
	// in this state either because it has been stopped or has not yet been started.
	StatusNotActive
)
