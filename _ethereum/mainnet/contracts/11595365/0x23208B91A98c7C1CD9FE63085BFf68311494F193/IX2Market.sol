// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IX2Market {
    function bullToken() external view returns (address);
    function bearToken() external view returns (address);
    function latestPrice() external view returns (uint256);
    function lastPrice() external view returns (uint176);
    function getDivisor(address token) external view returns (uint256);
    function getDivisors(uint256 _lastPrice, uint256 _nextPrice) external view returns (uint256, uint256);
    function setFunding(uint256 fundingPoints, uint256 fundingInterval) external;
    function previousBullDivisor() external view returns (uint64);
    function previousBearDivisor() external view returns (uint64);
    function cachedBullDivisor() external view returns (uint64);
    function cachedBearDivisor() external view returns (uint64);
}
