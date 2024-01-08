// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.10;

interface ISanctuary {
  function addManyToSanctuaryAndHeaven(
    address account,
    uint16[] calldata tokenIds
  ) external;

  function randomAngelOwner(uint256 seed) external view returns (address);
}
