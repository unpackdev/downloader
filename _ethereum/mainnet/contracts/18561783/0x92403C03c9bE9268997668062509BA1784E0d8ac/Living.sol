// SPDX-License-Identifier: ISC

pragma solidity ^0.8.0;

abstract contract Living {
    event Stopped(address user);
    event Started(address user);

    uint256 internal alive;

    modifier live {
        require(alive != 0, "Living/not-live");
        _;
    }

    function stop() internal {
        require(alive == 1, "Living/already-stop");
        alive = 0;

        emit Stopped(msg.sender);
    }

    function run() internal {
        require(alive == 0, "Living/already-live");
        alive = 1;

        emit Started(msg.sender);
    }
}