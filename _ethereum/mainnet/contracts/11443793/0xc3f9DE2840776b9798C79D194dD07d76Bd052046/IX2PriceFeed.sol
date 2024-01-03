// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IX2PriceFeed {
    function latestAnswer() external view returns (uint256);
    function latestTimestamp() external view returns (uint256);
}
