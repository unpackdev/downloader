// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./IERC20.sol";

interface TokenInterface is IERC20 {
   function decimals() external view returns (uint256);
}