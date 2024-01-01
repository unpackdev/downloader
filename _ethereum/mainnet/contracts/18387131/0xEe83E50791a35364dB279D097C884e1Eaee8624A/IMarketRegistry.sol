// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IMarketRegistry {
    function getMarketplaceFee(uint256 _marketId) external view returns (uint16);
}