// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;

interface ICurveVotingEscrow {
  function create_lock(uint256 value, uint256 unlockTime) external;
  function increase_amount(uint256 value) external;
  function increase_unlock_time(uint256 unlockTime) external;
}
