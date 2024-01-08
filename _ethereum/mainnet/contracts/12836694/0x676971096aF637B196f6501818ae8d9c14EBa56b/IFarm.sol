// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IVaultFarm {
  function deposit ( uint256 amount ) external;
  function depositFor ( uint256 amount, address holder ) external;
  function withdraw ( uint256 numberOfShares ) external;
  function withdrawAll (  ) external;
}
