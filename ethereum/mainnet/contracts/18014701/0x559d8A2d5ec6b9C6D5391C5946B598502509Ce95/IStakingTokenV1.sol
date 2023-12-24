// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IStakingV1.sol";

interface IStakingTokenV1 is IStakingV1 {
  function rewardsToken() external view returns (address);
  function recoverEth() external;
}
