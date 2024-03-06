package state

// Key defines a string type used for state keys within the application.
// It provides a method for easy conversion back to a native string type,
// facilitating interactions with external storage systems.
type Key string

// String returns the string representation of the Key.
// This method ensures the Key type can easily be converted back to a native string,
// allowing for seamless integration with systems expecting string keys.
func (s Key) String() string {
	return string(s)
}

// Predefined state keys for common blockchain-related values.
const (
	CurrentBlockHead     Key = "inspector:state:current-block-head-1"     // CurrentBlockHead represents the current head of the blockchain.
	LatestInspectedBlock Key = "inspector:state:latest-inspected-block-1" // LatestInspectedBlock represents the latest block that has been inspected by the application.
)
