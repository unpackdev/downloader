// SPDX-License-Identifier: None
pragma solidity ^0.7.5;

interface IRollover {
  function rollover(address _cover, uint48 _newTimestamp) external;
  function rolloverAccount(address _cover, uint48 _newTimestamp, address _account) external;
}