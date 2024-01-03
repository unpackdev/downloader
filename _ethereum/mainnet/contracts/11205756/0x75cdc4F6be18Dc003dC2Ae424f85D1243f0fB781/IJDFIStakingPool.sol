// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.4;

import "./IStakingPool.sol";

interface IJDFIStakingPool is IStakingPool {
  function stake (uint amount) external;
  function unstake (uint amount) external;
}
