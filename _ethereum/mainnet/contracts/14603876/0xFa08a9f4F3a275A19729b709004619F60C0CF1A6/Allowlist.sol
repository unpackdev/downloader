// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Ownable.sol";
import "./MerkleProof.sol";

/**
 * @title Allowlist
 * @notice Allowlist using MerkleProof.
 * @dev Use to generate root and proof https://github.com/miguelmota/merkletreejs
 */
contract Allowlist is Ownable {
    /// @notice small deposit limit to check for in Merkle proof
    uint256 public constant SMALL_AMOUNT = 1 ether;
    /// @notice large deposit limit to check for in Merkle proof
    uint256 public constant LARGE_AMOUNT = 2 ether;

    /// @notice Allowlist inclusion root
    bytes32 public merkleRoot;

    /**
     * @notice Set merkleRoot
     * @param _root new merkle root
     */
    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    /// @notice Verifies the Merkle proof and returns the max deposit amount for the given address.
    /// Creates 2 leaves, using 2 different deposit limits, and returns the valid limit, or zero if
    /// both leaves are invalid.
    /// @dev We make 2 leaves, since the user will not input their deposit limit.
    /// The original leaves in the Merkle Tree should contain an address and deposit limit in wei.
    /// @param _address address to check
    /// @param proof merkle proof verify
    function getAllowedAmount(address _address, bytes32[] calldata proof)
        public
        view
        returns (uint256)
    {
        bytes32 smallLeaf = keccak256(abi.encodePacked(_address, SMALL_AMOUNT));
        bytes32 largeLeaf = keccak256(abi.encodePacked(_address, LARGE_AMOUNT));

        if (MerkleProof.verify(proof, merkleRoot, smallLeaf)) {
            return SMALL_AMOUNT;
        } else if (MerkleProof.verify(proof, merkleRoot, largeLeaf)) {
            return LARGE_AMOUNT;
        }

        revert("Allowlist: invalid proof");
    }
}
