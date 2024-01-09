// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;
pragma abicoder v2;

interface ITwoBitUpgradeMerkle {
  function checkUpgradeStatus(
    uint8 currentLevel,
    uint8 upgradeType,
    uint256 tokenId,
    bytes32[] memory proof
  ) external returns (bool);
}