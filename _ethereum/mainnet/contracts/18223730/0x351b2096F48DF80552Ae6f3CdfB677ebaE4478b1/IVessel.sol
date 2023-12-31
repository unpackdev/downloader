// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IVessel {
  function burn(uint256 vesselId) external;
  function ownerOf(uint256 tokenId) external returns (address);
}