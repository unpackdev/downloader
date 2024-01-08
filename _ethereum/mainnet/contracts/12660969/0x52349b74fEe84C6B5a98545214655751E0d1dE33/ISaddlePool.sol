// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISaddlePool {
    function calculateSwap(uint8 from, uint8 to, uint256 dx) external view returns (uint256);
}