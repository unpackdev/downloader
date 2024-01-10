// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Proves inclusion on a merkle tree.
 */
library MerkleProof {
    // @notice verifies a proof of inclusion of a value in a Merkle tree
    function verify(
        bytes32 root,
        bytes32 leaf,
        bytes32[] memory proof,
        uint256[] memory positions
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (positions[i] == 1) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        return computedHash == root;
    }
}
