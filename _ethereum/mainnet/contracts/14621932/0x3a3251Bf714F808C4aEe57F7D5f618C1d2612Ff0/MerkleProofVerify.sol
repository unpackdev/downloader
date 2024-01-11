// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./MerkleProof.sol";

/// @title MerkleProofVerify Contract
/// @author Ahmed Ali Bhatti <github.com/ahmedali8>
contract MerkleProofVerify {
    /// @dev Returns the root.
    bytes32 public root;

    /// @dev Returns the proofHash.
    /// ipfs hash containing the json file of leaf proofs.
    string public proofHash;

    /// @dev Emitted when root is set.
    event RootSet(bytes32 root, string proofHash);

    /// @dev Error thrown when root is invalid.
    error InvalidRoot();

    /// @dev Returns boolean value for `_proof` and `_leaf`.
    function verify(bytes32[] memory _proof, bytes32 _leaf)
        public
        view
        virtual
        returns (bool)
    {
        return MerkleProof.verify(_proof, root, _leaf);
    }

    /// @dev Returns bytes32 hash for `_proof` and `_leaf`.
    function processProof(bytes32[] memory _proof, bytes32 _leaf)
        public
        pure
        virtual
        returns (bytes32)
    {
        return MerkleProof.processProof(_proof, _leaf);
    }

    /// @dev Sets `root` and `proofHash`.
    /// Emits a {RootSet} event indicating update of merkle root hash.
    /// @param _root - markle root
    /// @param _proofHash - ipfs hash containing json file of proofs.
    /// Requirements:
    /// - `_root` and `_proofHash` must be valid.
    function _setRoot(bytes32 _root, string memory _proofHash)
        internal
        virtual
    {
        if (_root == "" && bytes(_proofHash).length == 0) revert InvalidRoot();

        root = _root;
        proofHash = _proofHash;
        emit RootSet(_root, _proofHash);
    }
}
