// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.7.0;

interface IFeeSplitter {
  function nftRewardsVault() external view returns (address);

  function trigRewardsVault() external view returns (address);

  function treasuryVault() external view returns (address);

  function setTreasuryVault(address) external;

  function setTrigFee(uint256) external;

  function setKeeperFee(uint256) external;

  function update() external;
}
