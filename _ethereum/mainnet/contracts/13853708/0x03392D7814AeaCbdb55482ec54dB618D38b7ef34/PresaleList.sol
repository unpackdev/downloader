//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "./MerkleProof.sol";

contract PresaleList {
  function isOnList(
    bytes32 merkleRoot,
    bytes32[] memory proof,
    address claimer
  ) public pure returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(claimer));
    return MerkleProof.verify(proof, merkleRoot, leaf);
  }
}
