// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./IERC20.sol";

interface IChiToken is IERC20 {
    function mint(uint256 value) external;
    function freeFromUpTo(address from, uint256 value) external returns(uint256 freed);
}