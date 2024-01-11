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
    function start() public {
        require(state == STATE.CLOSED, "Can't start yet! Current state is not closed yet!");
        state = STATE.OPEN;
    }

    /**
     * @notice End the state.
     */
    function end() public {
        require(state == STATE.OPEN, "Not opened yet.");
        state = STATE.END;
    }

    /**
     * @notice Close the state.
     */
    function closed() public {
        require(state == STATE.END, "Not ended yet.");
        state = STATE.CLOSED;
    }

    /**
     * @notice Get current funding state in string.
     */
    function getCurrentState() public view returns (string memory) {
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
    function getCurrentStateNum() public view returns (uint32) {
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

     /**
     * @notice Update the funding state
     * @param newState - change to new state
     */
    function setState(uint32 newState) public  {
        require((newState >= 0 && newState <=2), "Invalid number for state. 0=OPEN 1=END 2=CLOSED");
        if (newState == 0)
            state = STATE.OPEN;
        else if(newState == 1)
            state = STATE.END;
        else if(newState == 2)
            state = STATE.CLOSED;
    }

}