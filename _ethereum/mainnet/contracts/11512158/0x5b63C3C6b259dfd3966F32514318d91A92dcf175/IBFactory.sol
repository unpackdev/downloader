// SPDX-License-Identifier: None

pragma solidity ^0.7.5;

import "./IBPool.sol";

interface IBFactory {
  function newBPool() external returns (IBPool);
}