pragma solidity ^0.8.11;

interface IveSDT {
  function create_lock(uint256 _value, uint256 _unlock_time) external;
}
