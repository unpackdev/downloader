// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;


interface ILendToAaveMigrator  {

  function AAVE() external returns (address);
  function LEND() external returns (address);
  function migrateFromLEND(uint256) external ;
}
