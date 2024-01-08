//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.6;

interface IUniVaultV1 {
  function getStorage() external view returns (address);
  function shouldUpgrade() external view returns (bool, address);
}