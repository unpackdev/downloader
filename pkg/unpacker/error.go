package unpacker

import (
	"context"
	"github.com/unpackdev/inspector/pkg/machine"
)

// ErrorContractHandler defines a handler for processing contracts that have encountered errors.
// It embeds context for runtime control and a reference to the Unpacker for accessing shared functionalities.
type ErrorContractHandler struct {
	ctx context.Context // Context allows for managing and cancelling operations.
	u   *Unpacker       // Reference to the Unpacker to leverage shared utilities and functions.
}

// NewErrorContractHandler initializes a new instance of ErrorContractHandler with a given context and unpacker reference.
// It returns a machine.Handler configured with Enter, Process, and Exit strategies for handling error states.
func NewErrorContractHandler(ctx context.Context, u *Unpacker) machine.Handler {
	bh := &ErrorContractHandler{ctx: ctx, u: u}
	return machine.Handler{
		Enter:   bh.Enter,
		Process: bh.Process,
		Exit:    bh.Exit,
	}
}

// Enter prepares the handler for processing an error state. It can be used to initialize or reset state
// before the core error handling logic is executed. Currently, it simply returns the input data unchanged.
func (dh *ErrorContractHandler) Enter(data machine.Data) (machine.Data, error) {
	return data, nil
}

// Process executes the main logic for handling contracts in an error state.
// This function transitions the contract to a final or resolution state, effectively marking the error handling as complete.
// Currently, it marks the process as done without altering the data.
// @TODO: Metrics should be written at this stage. I don't think anything else is necessary for now.
func (dh *ErrorContractHandler) Process(data machine.Data) (machine.State, machine.Data, error) {
	descriptor := toDescriptor(data)
	return DoneState, descriptor, nil
}

// Exit performs any necessary cleanup after the error processing is complete.
// This could involve releasing resources, logging, or other finalization activities. Currently, it returns the data unchanged.
func (dh *ErrorContractHandler) Exit(data machine.Data) (machine.Data, error) {
	return data, nil
}
