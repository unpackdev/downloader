// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC721.sol";

interface IRegistrar is IERC721 {
  // Checks if a domains metadata is locked
  function isDomainMetadataLocked(uint256 id) external view returns (bool);

  // Gets a domains current royalty amount
  function domainRoyaltyAmount(uint256 id) external view returns (uint256);

  // Sets the asked royalty amount on a domain (amount is a percentage with 5 decimal places)
  function setDomainRoyaltyAmount(uint256 id, uint256 amount) external;

  // Returns the parent domain of a child domain
  function parentOf(uint256 id) external view returns (uint256);

  //Gets a domain's minter
  function minterOf(uint256 id) external view returns (address);
}
