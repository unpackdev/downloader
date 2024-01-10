// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
Addresses:
  Rinkeby: 0x90098737eB7C3e73854daF1Da20dFf90d521929a
*/

interface IZNSHub {
  // Returns the owner of a zNA given by `domainId`
  function ownerOf(uint256 domainId) external view returns (address);
}
