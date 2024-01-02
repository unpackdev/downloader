// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "./MerkleProof.sol";

/**
 * @title MerkleDistributor
 * @dev A contract for distributing tokens using a merkle tree.
 */
abstract contract MerkleDistributor {
    // -----------------------------------------------------------------------
    // Storage variables
    // -----------------------------------------------------------------------

    /// @notice Mapping of id's to their corresponding merkle roots.
    mapping(uint256 => bytes32) public merkleRoots;
    /// @dev packed array of booleans for claims per merkle root id's.
    mapping(uint256 => mapping(uint256 => uint256)) private claimedBitMap;

    // -----------------------------------------------------------------------
    // Getters
    // -----------------------------------------------------------------------

    /**
     * @dev Checks if a merkle claim has been claimed from the merkle tree.
     *
     * @param id The id of the merkle root.
     * @param index The index of the claim.
     *
     * @return A boolean indicating whether the claim has been claimed.
     */
    function isClaimed(uint256 id, uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[id][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    // -----------------------------------------------------------------------
    // Internal functions
    // -----------------------------------------------------------------------

    /**
     * @dev Adds a merkle root for a specific id.
     *
     * @param id The id of the merkle root.
     * @param merkleRoot The merkle root to be added.
     *
     * Notes:
     * - All validations should be done in the parent contract.
     */
    function _addMerkleRoot(uint256 id, bytes32 merkleRoot) internal {
        merkleRoots[id] = merkleRoot;
    }

    /**
     * @dev Sets that a merkle claim has been claimed.
     *
     * @param id The id of the merkle root.
     * @param index The index of the claim.
     */
    function _setClaimed(uint256 id, uint256 index) internal {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[id][claimedWordIndex] =
            claimedBitMap[id][claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    /**
     * @dev Verifies a merkle claim using a provided merkle proof and leaf.
     *
     * @param id The id of the merkle root.
     * @param merkleProof The merkle proofs to be used for verification.
     * @param leaf The leaf to be used for verification.
     *
     * @return A boolean indicating whether the merkle proof is valid.
     */
    function _verify(
        uint256 id,
        bytes32[] calldata merkleProof,
        bytes32 leaf
    ) internal view returns (bool) {
        return MerkleProof.verify(merkleProof, merkleRoots[id], leaf);
    }
}
