// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - security@angelblock.io

    maintainers:
    - marcin@angelblock.io
    - piotr@angelblock.io
    - mikolaj@angelblock.io
    - sebastian@angelblock.io

    contributors:
    - domenico@angelblock.io

**************************************/

/**************************************
    
    Configurable utility

**************************************/

abstract contract Configurable {
    
    // enum
    enum State {
        UNCONFIGURED,
        CONFIGURED
    }

    // storage
    State public state;

    // events
    event Initialised(bytes args);
    event Configured(bytes args);
    
    // errors
    error InvalidState(State state, State expected);

    // modifiers
    modifier onlyInState(State _state) {
        
        // check state
        if (state != _state) {
            revert InvalidState(state, _state);
        }

        // enter function
        _;

    }

    // abstracts
    function configure(bytes calldata) external virtual;

}
