// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IVault {

  function deposit() external;

  function withdraw(address to, uint256 amount) external;

  function vaultBalance() external returns (uint256 reserves);

  function vaultExec() external;

  function reserveAsset() external view returns (address asset);

}
