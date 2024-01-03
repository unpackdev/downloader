// SPDX-License-Identifier: None
pragma solidity ^0.7.5;

interface IRollover {
  event RolloverCover(address indexed _account, address _protocol);

  function rollover(address _cover, uint48 _newTimestamp) external;
}