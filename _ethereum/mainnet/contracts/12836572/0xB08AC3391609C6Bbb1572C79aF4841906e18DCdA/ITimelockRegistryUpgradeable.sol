// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface ITimelockRegistryUpgradeable {
  function effectiveTimelock() external view returns (uint256);
  function isIVActiveGlobal(address iv) external view returns (bool);
  function isIVActiveForVault(address vault, address iv) external view returns (bool);
  function isIVInsuredByInsuranceVault(address vault, address iv) external view returns (bool);
  function vaultTimelockEnabled(address vault) external view returns(bool);
}