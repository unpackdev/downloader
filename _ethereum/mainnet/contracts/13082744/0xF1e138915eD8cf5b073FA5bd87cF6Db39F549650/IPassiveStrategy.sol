// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import "./IStrategy.sol";

interface IPassiveStrategy is IStrategy {
  function setKeeper(address _keeper) external;
}
