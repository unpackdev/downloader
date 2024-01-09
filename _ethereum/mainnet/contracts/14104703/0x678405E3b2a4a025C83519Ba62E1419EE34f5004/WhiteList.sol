// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./MerkleProof.sol";

contract WhiteList {
  mapping(address => bytes32) private merkleRoots;

  function isAllowed(
    address addressToVerify,
    bytes32[] memory proof,
    address publisher
  ) external view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(addressToVerify));
    return MerkleProof.verify(proof, merkleRoots[publisher], leaf);
  }

  function publishMerkleRoot(bytes32 _merkleRoot) external {
    merkleRoots[msg.sender] = _merkleRoot;
  }
}
