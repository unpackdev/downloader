package state

import "fmt"

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
	CurrentBlockHead            Key = "inspector:state:current-block-head-1" // CurrentBlockHead represents the current head of the blockchain.
	UnknownHeadBlock            Key = "unknown-head-key"
	LatestInspectedHeadBlock    Key = "inspector:state:latest-inspected-head-block-1"    // LatestInspectedHeadBlock represents the latest head block that has been inspected by the application.
	LatestInspectedArchiveBlock Key = "inspector:state:latest-inspected-archive-block-1" // LatestInspectedArchiveBlock represents the latest archive block that has been inspected by the application.
	ArchiveStartBlockNumber     Key = "inspector:state:archive-start-block-number"
	ArchiveEndBlockNumber       Key = "inspector:state:archive-end-block-number"
)

func GetHeadBlockKeyByDirection(direction string) (Key, error) {
	switch direction {
	case "head":
		return LatestInspectedHeadBlock, nil
	case "archive":
		return LatestInspectedArchiveBlock, nil
	default:
		return UnknownHeadBlock, fmt.Errorf(
			"failure to discover unknown block key by direction '%s'",
			direction,
		)
	}
}
