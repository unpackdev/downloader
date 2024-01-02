// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract SimplePausable {

    bool private paused;

    event Paused(address account);
    event Unpaused(address account);

    function pause() external {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external {
        paused = false;
        emit Unpaused(msg.sender);
    }

}

