// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./Pausable.sol";
import "./Ownable.sol";

contract BaseContract is Pausable, Ownable {
    function togglePausedState() external onlyOwner {
        paused() ? _unpause() : _pause();
    }
}
