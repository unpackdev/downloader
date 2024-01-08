// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IRandom {
  function rand(uint256 _range) external returns(uint256);
  function regenerateHash() external;
}
