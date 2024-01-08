// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./IERC20.sol";

interface IWeth9 is IERC20 {
  function deposit() external payable;

  function withdraw(uint256) external;
}
