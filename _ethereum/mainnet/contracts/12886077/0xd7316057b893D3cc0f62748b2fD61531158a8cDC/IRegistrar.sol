// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRegistrar
{
  // Checks if a domains metadata is locked
  function isDomainMetadataLocked(uint256 id) external view returns (bool);

  // Gets a domains current royalty amount
  function domainRoyaltyAmount(uint256 id) external view returns (uint256);

  //Gets a domain's minter
  function minterOf(uint256 id) external view returns (address);
}