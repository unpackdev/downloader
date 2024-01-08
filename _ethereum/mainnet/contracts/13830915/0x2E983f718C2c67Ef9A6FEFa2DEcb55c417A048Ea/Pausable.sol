// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";


//allows pausing of critical functions in the contract
contract Pausable is Ownable {

    bool public paused = false; //start unpaused

    event Paused();
    event Unpaused();

    modifier whenNotPaused() {
        require(!paused,"Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused,"Contract is not paused");
        _;
    }

    function Pause() onlyOwner whenNotPaused external {
        paused = true;
        emit Paused();
    }

    function Unpause() onlyOwner whenPaused external {
        paused = false;
        emit Unpaused();
    }
}