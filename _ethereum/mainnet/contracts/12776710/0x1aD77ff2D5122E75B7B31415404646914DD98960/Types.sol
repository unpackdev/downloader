// SPDX-License-Identifier: MIT

pragma solidity ^0.5.12;

library Types {
    struct Stream {
        address sender;
        address recipient;
        uint256 deposit;
        address tokenAddress;
        uint256 startTime;
        uint256 stopTime;
        uint256 remainingBalance;
        uint256 ratePerSecond;
        bool isEntity;
    }
}
