// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/**
 * @title MerkleProofIndexed
 * @dev Merkle proof verification based on
 * https://github.com/ameensol/merkle-tree-solidity/blob/master/src/MerkleProof.sol
 */
library MerkleProofIndexed {
    /**
     * @dev Verifies a Merkle proof proving the existence of a leaf in a Merkle tree. Assumes that the merkle tree
     * you are passing is symmetric, so the number of leaves must be a power of 2 in order to properly verify the index
     * of the leaf that is meant to be proven
     * @param proof Merkle proof containing sibling hashes on the branch from the leaf to the root of the Merkle tree
     * @param root Merkle root
     * @param leaf Leaf of Merkle tree
     * @param leafIndex the index of the leaf you are trying to prove
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf,
        uint256 leafIndex
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;
        bytes32 proofElement;

        for (uint256 i = 0; i < proof.length; i++) {
            proofElement = proof[i];

            if ((leafIndex >> i) % 2 == 0) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }
        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}
