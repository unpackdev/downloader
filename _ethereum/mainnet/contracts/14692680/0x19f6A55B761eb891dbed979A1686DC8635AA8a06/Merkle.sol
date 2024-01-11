// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

/// @author tae-jin.eth
/// @title Provides merkle proof verification logic. References: https://github.com/miguelmota/merkletreejs-solidity
contract Merkle {
  function verifyProof(
    bytes32 root,
    bytes32 leaf,
    bytes32[] memory proof
  ) public pure returns (bool) {
    bytes32 currentHash = leaf;

    for(uint256 i = 0; i < proof.length; i++) {
      bytes32 proofElement = proof[i];

      // hash in order
      currentHash = currentHash <= proofElement ? 
        keccak256(abi.encodePacked(currentHash, proofElement)) 
        : keccak256(abi.encodePacked(proofElement, currentHash));      
    }

    return currentHash == root;
  }
}