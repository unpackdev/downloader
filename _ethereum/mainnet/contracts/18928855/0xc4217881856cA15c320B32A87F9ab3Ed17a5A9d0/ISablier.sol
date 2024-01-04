// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

struct SablierStream {
    address sender;
    address recipient;
    uint256 deposit;
    address token;
    uint256 startTime;
    uint256 stopTime;
    uint256 remainingBalance;
    uint256 ratePerSecond;
}

interface ISablier {
    function createStream(address recipent, uint256 deposit, address tokenAddress, uint256 startTime, uint256 stopTime)
        external
        returns (uint256);

    function getStream(uint256 streamId) external view returns (SablierStream memory);
}
