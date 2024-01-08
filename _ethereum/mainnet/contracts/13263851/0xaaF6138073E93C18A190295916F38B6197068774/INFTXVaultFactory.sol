// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

interface INFTXVaultFactory {
  // Read functions.
  function numVaults() external view returns (uint256);
  function zapContract() external view returns (address);
  function feeDistributor() external view returns (address);
  function eligibilityManager() external view returns (address);
  function vault(uint256 vaultId) external view returns (address);
  function vaultsForAsset(address asset) external view returns (address[] memory);
  function isLocked(uint256 id) external view returns (bool);
  function excludedFromFees(address addr) external view returns (bool);
  function factoryMintFee() external view returns (uint64);
  function factoryRandomRedeemFee() external view returns (uint64);
  function factoryTargetRedeemFee() external view returns (uint64);
  function vaultFees(uint256 vaultId) external view returns (uint256, uint256, uint256);
}
