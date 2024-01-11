// SPDX-License-Identifier: MIT
// Creator: https://cojodi.com
pragma solidity ^0.8.0;

import "./MerkleProof.sol";
import "./Strings.sol";
import "./Ownable.sol";

contract MerkleStorage is Ownable {
  using Strings for uint256;

  bytes32 public storageMerkleRoot;

  constructor(bytes32 storageMerkleRoot_) {
    storageMerkleRoot = storageMerkleRoot_;
  }

  function setStorageMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
    storageMerkleRoot = merkleRoot_;
  }

  function isInStorage(bytes32[] calldata merkleProof_, bytes memory packed_)
    internal
    view
    returns (bool)
  {
    bytes32 leaf = keccak256(packed_);
    return MerkleProof.verify(merkleProof_, storageMerkleRoot, leaf);
  }
}
