package machine

import (
	"context"
	"errors"
	"fmt"
	"sync"
	"time"
)

// StateMachine represents the state machine itself. It manages the current state,
// the available states and their handlers, and the state transitions.
type StateMachine struct {
	ctx             context.Context            // The context for managing cancellation and deadlines.
	currentState    State                      // The current state of the machine.
	finalState      State                      // The designated final state of the machine.
	errorState      State                      // The designated error state of the machine.
	states          map[State]Handler          // A map of states and their associated handlers.
	transitions     map[State]map[Action]State // A map of transitions from states based on actions.
	data            Data                       // The data being carried through the state machine.
	processedStates []State                    // A slice of states that have been processed.
	history         []State                    // A history of all the states the machine has been in.
	paused          bool                       // Flag to indicate if the state machine is paused.
	mu              sync.Mutex                 // Mutex to ensure thread safety.
}

// NewStateMachine creates and returns a new StateMachine with the specified initial state and data.
func NewStateMachine(ctx context.Context, initialState State, data Data) *StateMachine {
	return &StateMachine{
		ctx:             ctx,
		currentState:    initialState,
		states:          make(map[State]Handler),
		transitions:     make(map[State]map[Action]State),
		data:            data,
		processedStates: []State{initialState},
		history:         []State{initialState},
	}
}

// RegisterState adds a new state and its associated handler to the state machine.
func (sm *StateMachine) RegisterState(state State, handler Handler) {
	sm.mu.Lock()
	defer sm.mu.Unlock()
	sm.states[state] = handler
}

// RegisterFinalState sets the final state of the state machine. Reaching this state means the machine's process is complete.
func (sm *StateMachine) RegisterFinalState(state State) error {
	sm.mu.Lock()
	defer sm.mu.Unlock()
	sm.finalState = state
	return nil
}

// RegisterErrorState sets the error state of the state machine. This state is used when an error occurs in any state transition or processing.
func (sm *StateMachine) RegisterErrorState(state State) error {
	sm.mu.Lock()
	defer sm.mu.Unlock()
	if _, exists := sm.states[state]; !exists {
		return fmt.Errorf("handler for error state '%s' is not registered", state)
	}
	sm.errorState = state
	return nil
}

// RegisterTransition defines a transition from one state to another based on a given action.
func (sm *StateMachine) RegisterTransition(from State, action Action, to State) error {
	sm.mu.Lock()
	defer sm.mu.Unlock()
	if _, exists := sm.states[from]; !exists {
		return fmt.Errorf("handler for source state '%s' is not registered", from)
	}
	if _, exists := sm.states[to]; !exists {
		return fmt.Errorf("handler for destination state '%s' from '%s' is not registered", to, from)
	}
	if sm.transitions[from] == nil {
		sm.transitions[from] = make(map[Action]State)
	}
	sm.transitions[from][action] = to
	return nil
}

// Trigger initiates the transition from the current state to the next state based on the provided action.
func (sm *StateMachine) Trigger(action Action) error {
	sm.mu.Lock()
	defer sm.mu.Unlock()
	if sm.paused {
		return errors.New("state machine is paused")
	}

	nextState, ok := sm.transitions[sm.currentState][action]
	if !ok {
		return fmt.Errorf("invalid transition from state %s with action %s", sm.currentState, action)
	}

	if err := sm.transition(nextState); err != nil {
		if sm.errorState != "" {
			return sm.transition(sm.errorState)
		}
		return err
	}
	return nil
}

// Process runs the state machine process, handling transitions and state processing based on the defined rules and transitions.
func (sm *StateMachine) Process() error {
	for {
		sm.mu.Lock()
		if sm.paused {
			sm.mu.Unlock()
			return errors.New("state machine is paused")
		}
		if sm.currentState == sm.finalState {
			sm.mu.Unlock()
			return nil
		}
		handler, ok := sm.states[sm.currentState]
		if !ok {
			sm.mu.Unlock()
			return fmt.Errorf("invalid state: %s", sm.currentState)
		}
		sm.mu.Unlock()

		select {
		case <-sm.ctx.Done():
			return sm.ctx.Err()
		default:
		}

		var err error
		var nextState State

		if handler.Enter != nil {
			sm.data, err = handler.Enter(sm.data)
			if err != nil {
				if sm.errorState != "" {
					return sm.transition(sm.errorState)
				}
				return err
			}
		}

		nextState, sm.data, err = handler.Process(sm.data)
		if err != nil {
			if sm.errorState != "" {
				return sm.transition(sm.errorState)
			}
			return err
		}

		if _, exists := sm.states[nextState]; !exists && nextState != sm.finalState && nextState != "" {
			if sm.errorState != "" {
				return sm.transition(sm.errorState)
			}
			return fmt.Errorf("invalid next state: %s", nextState)
		}

		if handler.Exit != nil {
			sm.data, err = handler.Exit(sm.data)
			if err != nil {
				if sm.errorState != "" {
					return sm.transition(sm.errorState)
				}
				return err
			}
		}

		if err := sm.transition(nextState); err != nil {
			if sm.errorState != "" {
				return sm.transition(sm.errorState)
			}
			return err
		}
		if nextState == sm.finalState {
			return nil
		}
	}
}

// GetCurrentState returns the current state of the state machine.
func (sm *StateMachine) GetCurrentState() State {
	sm.mu.Lock()
	defer sm.mu.Unlock()
	return sm.currentState
}

// GetProcessedStates returns a slice of all states that have been processed so far.
func (sm *StateMachine) GetProcessedStates() []State {
	sm.mu.Lock()
	defer sm.mu.Unlock()
	return sm.processedStates
}

// GetHistory returns the history of all the states the machine has been in.
func (sm *StateMachine) GetHistory() []State {
	sm.mu.Lock()
	defer sm.mu.Unlock()
	return sm.history
}

// Pause pauses the state machine process. No new transitions or state processing will occur while paused.
func (sm *StateMachine) Pause() {
	sm.mu.Lock()
	defer sm.mu.Unlock()
	sm.paused = true
}

// Resume resumes the state machine process after being paused.
func (sm *StateMachine) Resume() {
	sm.mu.Lock()
	defer sm.mu.Unlock()
	sm.paused = false
}

// Timeout introduces a delay in the state machine processing, useful for testing and simulating time-based scenarios.
func (sm *StateMachine) Timeout(duration time.Duration) {
	time.Sleep(duration)
}

// Destroy cleans up the state machine, removing all states, transitions, and data. It essentially resets the machine to its initial state.
func (sm *StateMachine) Destroy() {
	sm.mu.Lock()
	defer sm.mu.Unlock()
	sm.states = nil
	sm.transitions = nil
	sm.data = nil
	sm.processedStates = nil
	sm.history = nil
}

// transition handles the internal transition logic from one state to another.
func (sm *StateMachine) transition(nextState State) error {
	sm.mu.Lock()
	defer sm.mu.Unlock()

	sm.processedStates = append(sm.processedStates, nextState)
	sm.history = append(sm.history, nextState)
	sm.currentState = nextState
	return nil
}
