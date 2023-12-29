package machine

// State represents a state in the state machine. It is a simple string type
// to facilitate easy identification and comparison of different states.
type State string

// String returns the string representation of the State.
func (s State) String() string {
	return string(s)
}

// Action represents an action that triggers state transitions in the state machine.
type Action string

// String returns the string representation of the Action.
func (a Action) String() string {
	return string(a)
}

// Data represents the data carried through the state machine. It can be of any type,
// allowing for flexibility in what information is passed between states.
type Data any
