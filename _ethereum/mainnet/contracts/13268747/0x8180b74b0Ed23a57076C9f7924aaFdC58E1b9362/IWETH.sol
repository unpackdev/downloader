// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.7;

import "./IERC20.sol";

interface IWETH is IERC20 {
  function deposit() external payable;

  function withdraw(uint256) external;
}
