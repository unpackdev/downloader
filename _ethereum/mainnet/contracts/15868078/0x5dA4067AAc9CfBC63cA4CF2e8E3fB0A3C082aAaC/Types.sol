// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Money Streamer Types
 * @author Wage3 (@wage3xyz)
 */
library Types {
    struct Stream {
        uint256 id;
        uint256 deposit;
        uint256 ratePerSecond;
        uint256 remainingBalance;
        uint256 startTime;
        uint256 stopTime;
        address recipient;
        address sender;
        address tokenAddress;
        bool isActive;
        bool isCanceled;
        bool isFinished;
    }
}
