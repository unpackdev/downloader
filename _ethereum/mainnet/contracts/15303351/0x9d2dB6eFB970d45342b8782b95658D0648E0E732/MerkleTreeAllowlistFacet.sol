// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControlModifiers.sol";
import "./BaseNFTModifiers.sol";
import "./PausableModifiers.sol";
import "./MerkleTreeAllowlistLib.sol";

contract MerkleTreeAllowlistFacet is
    AccessControlModifiers,
    SaleStateModifiers,
    PausableModifiers
{
    function setAllowlistMerkleRoot(bytes32 _allowlistMerkleRoot)
        public
        onlyOperator
        whenNotPaused
    {
        MerkleTreeAllowlistLib.setAllowlistMerkleRoot(_allowlistMerkleRoot);
    }

    function allowlistMint(uint256 _quantity, bytes32[] calldata _merkleProof)
        public
        payable
        whenNotPaused
        onlyAtSaleState(2)
        returns (uint256)
    {
        return MerkleTreeAllowlistLib.allowlistMint(_quantity, _merkleProof);
    }

    function isAddressOnAllowlist(
        address _maybeAllowlistAddress,
        bytes32[] calldata _merkleProof
    ) public view returns (bool) {
        return
            MerkleTreeAllowlistLib.isAddressOnAllowlist(
                _maybeAllowlistAddress,
                _merkleProof
            );
    }

    function getAllowlistMerkleRoot() public view returns (bytes32) {
        return
            MerkleTreeAllowlistLib
                .merkleTreeAllowlistStorage()
                .allowlistMerkleRoot;
    }
}
