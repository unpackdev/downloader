// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

contract State {

    enum STATE { OPEN, END, CLOSED }
    STATE internal state;

    constructor() {
        state = STATE.CLOSED;
    }

    /**
     * @notice Open the funding account.  Users can start funding now.
     */
    function start() external {
        require(state == STATE.CLOSED, "Can't start yet! Current state is not closed yet!");
        state = STATE.OPEN;
    }

    /**
     * @notice End the state.
     */
    function end() external {
        require(state == STATE.OPEN, "Not opened yet.");
        state = STATE.END;
    }

    /**
     * @notice Close the state.
     */
    function closed() external {
        require(state == STATE.END, "Not ended yet.");
        state = STATE.CLOSED;
    }

    /**
     * @notice Get current funding state in string.
     */
    function getCurrentState() external view returns (string memory) {
        require((state == STATE.OPEN || state == STATE.END || state == STATE.CLOSED), "unknown state.");
        if (state == STATE.OPEN)
            return "open";
        else if (state == STATE.END)
            return "end";
        else if (state == STATE.CLOSED)
            return "closed";
        else 
            return "unknow state";
    }

    /**
     * @notice Get current funding state in enum STATE type.
     */
    function getCurrentStateType() external view returns (STATE) {
        require((state == STATE.OPEN || state == STATE.END || state == STATE.CLOSED), "unknown state.");
        return state;
    }


     /**
     * @notice Update the funding state
     * @param newState - change to new state
     */
    function setState(uint32 newState) external  {
        require((newState >= 0 && newState <=2), "Invalid number for state. 0=OPEN 1=END 2=CLOSED");
        if (newState == 0)
            state = STATE.OPEN;
        else if(newState == 1)
            state = STATE.END;
        else if(newState == 2)
            state = STATE.CLOSED;
    }

    /**
     * @notice Update the funding state
     * @param newState - change to new state
     */
    function setStateType(STATE newState) external {
        require((newState == STATE.OPEN || newState == STATE.END || newState == STATE.CLOSED), "unknown state.");
        state = newState;
    }

    /**
     * @notice Get the STATE.
     */
    function getState() external view returns (STATE) {
        return state;
    }

    /**
     * @notice Get the OPEN STATE 
     */
    function getOpenState() external pure returns (STATE) {
        return STATE.OPEN;
    }

    /**
     * @notice Get the END STATE 
     */
    function getEndState() external pure returns (STATE) {
        return STATE.END;
    }

    /**
     * @notice Get the CLOSED STATE 
     */
    function getClosedState() external pure returns (STATE) {
        return STATE.CLOSED;
    }
}