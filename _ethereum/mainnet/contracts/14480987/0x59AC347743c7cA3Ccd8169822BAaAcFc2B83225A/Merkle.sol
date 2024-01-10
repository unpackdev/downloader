//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Merkle
 * @author gotbit
 */

contract Merkle {
    /// @dev verifies ogs
    /// @param proof array of bytes for merkle tree verifing
    /// @param root tree's root
    /// @param leaf keccak256 of user address
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) public pure returns (bool) {
        bytes32 hash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            hash = hash < proofElement
                ? keccak256(abi.encode(hash, proofElement))
                : keccak256(abi.encode(proofElement, hash));
        }
        return hash == root;
    }
}
