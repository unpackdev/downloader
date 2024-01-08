// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

import "./Ownable.sol";

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
abstract contract MerkleProof is Ownable {
    string private MERKLE_CHANGES_DISABLED = "MerkleRoot changes are disabled";

    // merkle tree root used to validate if the sender can mint
    bytes32 public merkleRootMintFree;
    bytes32 public merkleRootGoldMintFree;
    bytes32 public merkleRoot;

    /**
     * @dev Set the merkle tree mint free root hash
     * @param merkleRoot_ hash to save
     */
    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
    }

    /**
     * @dev Set the merkle tree mint free root hash
     * @param merkleRootMintFree_ hash to save
     */
    function setMerkleRootMintFree(bytes32 merkleRootMintFree_)
        external
        onlyOwner
    {
        merkleRootMintFree = merkleRootMintFree_;
    }

    /**
     * @dev Set the merkle tree gold mint free root hash
     * @param merkleRootGoldMintFree_ hash to save
     */
    function setMerkleRootGoldMintFree(bytes32 merkleRootGoldMintFree_)
        external
        onlyOwner
    {
        merkleRootGoldMintFree = merkleRootGoldMintFree_;
    }

    /**
     * @dev Returns true if a leaf can be proved to be a part of a Merkle tree
     * defined by root. For this, a proof must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     * @param proof hashes to validate
     * @param merkleRoot_ merkle root to compare with
     */
    function hasValidProof(bytes32[] memory proof, bytes32 merkleRoot_)
        internal
        view
    {
        bytes32 computedHash = keccak256(abi.encodePacked(msg.sender));

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            computedHash = keccak256(
                computedHash <= proofElement
                    ? abi.encodePacked(computedHash, proofElement)
                    : abi.encodePacked(proofElement, computedHash)
            );
        }

        // Check if the computed hash (root) is equal to the provided root
        require(computedHash == merkleRoot_, "the proof is not valid");
    }
}
