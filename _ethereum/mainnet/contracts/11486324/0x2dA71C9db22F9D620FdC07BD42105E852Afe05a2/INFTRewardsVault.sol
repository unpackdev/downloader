// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.7.0;

interface INFTRewardsVault {
  function update(uint256) external;

  function deposit(uint256, uint256) external;

  function withdraw(uint256, uint256) external;
}
