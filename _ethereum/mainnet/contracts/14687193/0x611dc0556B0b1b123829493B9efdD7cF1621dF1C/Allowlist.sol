// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Ownable.sol";
import "./MerkleProof.sol";

/**
 * @title Allowlist
 * @notice Allowlist using MerkleProof.
 * @dev Use to generate root and proof: https://github.com/miguelmota/merkletreejs
 */
contract Allowlist is Ownable {
    /// @notice Allowlist inclusion root
    bytes32 public merkleRoot;

    /**
     * @notice Set merkleRoot
     * @param _root new merkle root
     */
    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    /// @notice Verifies the Merkle proof and returns true if wallet is allowlisted
    /// @param _address address to check
    /// @param proof merkle proof verify
    function isAllowlisted(address _address, bytes32[] calldata proof) public view returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(_address)));
    }
}
