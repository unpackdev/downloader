// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IRenaswapV1Wrapper {
    function addWrappedToken(address token, address pair) external returns (uint256 id);
    function balanceFor(address token, address account) external view returns (uint256);
    function rBurn(address token, uint256 burnDivisor) external;
}