// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2015, 2016, 2017 Dapphub
// Adapted by Ethereum Community 2021
pragma solidity ^0.8.0;
import "./IERC20.sol";

interface IWETH9 is IERC20 {
  function deposit() external payable;

  function withdraw(uint256 _amount) external;
}