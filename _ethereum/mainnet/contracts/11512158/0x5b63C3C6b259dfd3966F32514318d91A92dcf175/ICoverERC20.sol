// SPDX-License-Identifier: None

pragma solidity ^0.7.5;

import "./IERC20.sol";

interface ICoverERC20 is IERC20 {
  function owner() external view returns (address);
}