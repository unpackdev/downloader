// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IPriceOracle {
    function addToken(address token) external returns (bool success);
    function update(address token) external;
    function priceOf(address token, uint256 amount) external view returns (uint256 daiAmount);
}