// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

contract State {

    enum STATE { OPEN, END, CLOSED }
    STATE state;

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
     * @notice Get current funding state in Number.
     */
    function getCurrentStateNum() external view returns (uint32) {
        require((state == STATE.OPEN || state == STATE.END || state == STATE.CLOSED), "unknown state.");
        if (state == STATE.OPEN)
            return 0;
        else if (state == STATE.END)
            return 1;
        else if (state == STATE.CLOSED)
            return 2;
        else
            return 3;
    }
}