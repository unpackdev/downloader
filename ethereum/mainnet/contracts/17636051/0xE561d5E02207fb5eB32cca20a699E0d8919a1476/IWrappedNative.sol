// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IWrappedNative is IERC20 {
  function deposit() external payable;
}
