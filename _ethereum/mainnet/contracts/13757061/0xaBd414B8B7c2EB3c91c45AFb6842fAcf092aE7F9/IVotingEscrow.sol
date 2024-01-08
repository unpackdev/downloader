// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IVotingEscrow {
  function locked(address _addr) external view returns (int128, uint256);
  function create_lock_for(address _addr, uint256 _value, uint256 _unlock_time) external;
  function deposit_for(address _addr, uint256 _value) external;
  function withdraw_for(address _addr) external;
}
