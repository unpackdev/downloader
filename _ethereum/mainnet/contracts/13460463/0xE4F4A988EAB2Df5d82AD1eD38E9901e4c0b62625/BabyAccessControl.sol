pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "./Ownable.sol";

contract BabyAccessControl is Ownable{

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused {
        require(paused);
        _;
    }

    function pause() external onlyOwner whenNotPaused {
        paused = true;
    }

    function unpause() public virtual onlyOwner whenPaused {
        // can't unpause if contract was upgraded
        paused = false;
    }
}
