// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IStakeReceiver {
  function onStakeReceived(address from, uint256 stakeId) external;
}
