package machine

// Handler defines the functions to execute when entering, processing, and exiting a state.
// Each function can modify the machine's data and optionally change the state.
type Handler struct {
	Enter   func(Data) (Data, error)        // Function executed when entering a state.
	Process func(Data) (State, Data, error) // Function executed when processing a state.
	Exit    func(Data) (Data, error)        // Function executed when exiting a state.
}
