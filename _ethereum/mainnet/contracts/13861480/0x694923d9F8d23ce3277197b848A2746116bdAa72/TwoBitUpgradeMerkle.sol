// SPDX-License-Identifier: MIT

import "./MerkleProof.sol";
import "./Context.sol";
import "./Ownable.sol";

pragma solidity 0.8.10;
pragma abicoder v2;

contract TwoBitClickUpgradeMerkle is Ownable {
  using MerkleProof for bytes32[];
  bytes32 public merkleRoot;
  event UpgradesReady();

  function checkUpgradeStatus(
    uint8 currentLevel,
    uint8 upgradeType,
    uint256 tokenId,
    bytes32[] memory proof
  ) external view returns (bool) {
    if (_verify(_leaf(currentLevel, upgradeType, tokenId), proof)) {
      return true;
    }

    return false;
  }

  function _leaf(
    uint8 currentLevel,
    uint8 upgradeType,
    uint256 tokenId
  ) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(currentLevel, upgradeType, tokenId));
  }

  function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
    return MerkleProof.verify(proof, merkleRoot, leaf);
  }

  function setRoot(bytes32 root) public onlyOwner {
    merkleRoot = root;
    emit UpgradesReady();
  }
}