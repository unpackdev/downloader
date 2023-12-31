// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IPoolContract {
  function getEndStaker() external view returns(address end_staker_address);
}
