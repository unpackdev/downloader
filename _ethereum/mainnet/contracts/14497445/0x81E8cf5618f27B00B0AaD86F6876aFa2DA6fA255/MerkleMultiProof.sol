// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// @credit: https://github.com/miguelmota/merkletreejs-multiproof-solidity#example
library MerkleMultiProof {
    function calculateMultiMerkleRoot(
        bytes32[] memory leafs,
        bytes32[] memory proofs,
        bool[] memory proofFlag
    ) public pure returns (bytes32 merkleRoot) {
        uint256 leafsLen = leafs.length;
        uint256 totalHashes = proofFlag.length;
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        for (uint256 i = 0; i < totalHashes; i++) {
            hashes[i] = hashPair(
                proofFlag[i] ? (leafPos < leafsLen ? leafs[leafPos++] : hashes[hashPos++]) : proofs[proofPos++],
                leafPos < leafsLen ? leafs[leafPos++] : hashes[hashPos++]
            );
        }

        return hashes[totalHashes - 1];
    }

    function hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? hash_node(a, b) : hash_node(b, a);
    }

    function hash_node(bytes32 left, bytes32 right) private pure returns (bytes32 hash) {
        assembly {
            mstore(0x00, left)
            mstore(0x20, right)
            hash := keccak256(0x00, 0x40)
        }
        return hash;
    }

    function verifyMultiProof(
        bytes32 root,
        bytes32[] memory leafs,
        bytes32[] memory proofs,
        bool[] memory proofFlag
    ) public pure returns (bool) {
        return calculateMultiMerkleRoot(leafs, proofs, proofFlag) == root;
    }
}
