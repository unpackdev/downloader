// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

interface IEditionSingleMintable {
  function numberCanMint() external view returns (uint256);
  function owner() external view returns (address);
}