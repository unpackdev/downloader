// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC20.sol";

interface IERC20Wrapper is IERC20 {
    function deposit(address from, uint256 amount) external returns (uint256);
    function withdraw(address to, uint256 amount) external;
    function underlying() external view returns (IERC20);
}