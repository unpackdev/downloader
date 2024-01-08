// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IVillage {
  function randomVikingOwner(uint256 seed) external view returns (address);
}
