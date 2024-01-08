// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

import "./Ownable.sol";

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
abstract contract MerkleProof is Ownable {
    string private MERKLE_CHANGES_DISABLED = "MerkleRoot changes are disabled";

    // merkle tree root used to validate if the sender can mint
    bytes32 public merkleRoot;
    bytes32 public merkleRootFreeMint;

    bool public canChangeMerkleRoot = true;
    bool public canChangeFreeMintMerkleRoot = true;

    /**
     * @dev Disable changes for merkle root
     */
    function disableMerkleRootChanges() external onlyOwner {
        require(canChangeMerkleRoot, MERKLE_CHANGES_DISABLED);
        canChangeMerkleRoot = false;
    }

    /**
     * @dev Set the merkle tree root  hash
     * @param merkleRoot_ hash to save
     */
    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        require(canChangeMerkleRoot, MERKLE_CHANGES_DISABLED);
        merkleRoot = merkleRoot_;
    }

    /**
     * @dev Disable changes for merkle root
     */
    function disableFreeMintMerkleRootChanges() external onlyOwner {
        require(canChangeFreeMintMerkleRoot, MERKLE_CHANGES_DISABLED);
        canChangeFreeMintMerkleRoot = false;
    }

    /**
     * @dev Set the merkle tree root  hash
     * @param merkleRootFreeMint_ hash to save
     */
    function setFreeMintMerkleRoot(bytes32 merkleRootFreeMint_)
        external
        onlyOwner
    {
        require(canChangeFreeMintMerkleRoot, MERKLE_CHANGES_DISABLED);
        merkleRootFreeMint = merkleRootFreeMint_;
    }

    /**
     * @dev Returns true if a leaf can be proved to be a part of a Merkle tree
     * defined by root. For this, a proof must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     * @param proof hashes to validate
     */
    function hasValidProof(bytes32[] memory proof, bytes32 merkleRoot_)
        internal
        view
    {
        bytes32 computedHash = keccak256(abi.encodePacked(msg.sender));

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
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
        require(computedHash == merkleRoot_, "the proof is not valid");
    }
}
