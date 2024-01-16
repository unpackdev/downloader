//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./MerkleProofUpgradeable.sol";

contract ClonableMerkleWhitelist {

  bytes32 public merkleRoot;

  function initialize(bytes32 _merkleRoot) external {
    require(merkleRoot == bytes32(0x00), "ALREADY_INITIALIZED");
    merkleRoot = _merkleRoot;
  }

  function isValidMerkleProof(bytes32[] calldata _merkleProof, address _minter, uint96 _amount) external view returns (bool) {
    require(merkleRoot != bytes32(0x00), "NOT_INITIALIZED");
    bytes32 leaf = keccak256(abi.encodePacked(_minter, _amount));
    bool result = MerkleProofUpgradeable.verify(_merkleProof, merkleRoot, leaf);
    require(result, 'INVALID_MERKLE_PROOF');
    return result;
  }

}