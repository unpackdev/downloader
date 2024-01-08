//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./MerkleProof.sol";

/// @title AllowList
/// @notice Adds simple merkle-tree based allow-list functionality to a contract.
contract AllowList {
    /// @notice stores the Merkle Tree root.
    bytes32 internal _merkleTreeRoot;

    /// @notice Sets the new merkle tree root
    /// @param newMerkleTreeRoot the new root of the merkle tree
    function _setMerkleTreeRoot(bytes32 newMerkleTreeRoot) internal {
        require(_merkleTreeRoot != newMerkleTreeRoot, "NO_CHANGES");
        _merkleTreeRoot = newMerkleTreeRoot;
    }

    /// @notice test if an address is part of the merkle tree
    /// @param _address the address to verify
    /// @param proof array of other hashes for proof calculation
    /// @return true if the address is part of the merkle tree
    function isAddressInAllowList(address _address, bytes32[] calldata proof)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(proof, _merkleTreeRoot, leaf);
    }
}
