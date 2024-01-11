// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./OwnableUpgradeable.sol";


abstract contract PausableUpgradeable is OwnableUpgradeable {
    uint public lastPauseTime;
    bool public paused;

    event PauseChanged(bool isPaused);

    modifier notPaused {
        require(!paused, "!paused");
        _;
    }

    function __PausableUpgradeable_init() internal initializer {
        __Ownable_init();
        require(owner() != address(0), "!owner");
    }

    function setPaused(bool _paused) external onlyOwner {
        if (_paused == paused) return;

        paused = _paused;
        if (paused) lastPauseTime = block.timestamp;
        emit PauseChanged(paused);
    }

    uint[49] private __gap;
}
