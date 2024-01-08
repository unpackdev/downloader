// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./MerkleProof.sol";

/**
 * @title NFTC Claimlist Implementation
 * @author @NiftyMike, NFT Culture
 * @dev "Claimlist" - an approach for whitelist minting backed by a MerkleTree.
 * Cheap to set the master claim, not that expensive to check the claim. Requires
 * off-chain generation of the MerkleTree.
 *
 * Please report bugs or security issues to @author
 * Please credit @author if you re-use this code
 */
contract NFTCClaimlist is Ownable {
    using MerkleProof for bytes32[];

    bytes32 private _masterClaim;
    mapping(address => uint256) private _nextClaimIndex;

    function setMasterClaim(bytes32 __masterClaim) external onlyOwner {
        _masterClaim = __masterClaim;
    }

    function getLeafFor(address wallet, uint256 index)
        external
        pure
        returns (bytes32)
    {
        // Both the contract and the caller need to be able to generate the
        // leaves in a perfectly identical manner, so to make this easier,
        // exposing the function directly from the contract.
        return _generateLeaf(wallet, index);
    }

    function checkClaim(
        address wallet,
        uint256 index,
        bytes32[] memory claim
    ) external view returns (bool) {
        return claim.verify(_masterClaim, _generateLeaf(wallet, index));
    }

    function getNextIndex(address wallet) external view returns (uint256) {
        return _getNextIndex(wallet);
    }

    function _getNextIndex(address wallet) internal view returns (uint256) {
        return _nextClaimIndex[wallet];
    }

    function _generateLeaf(address wallet, uint256 index)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(wallet, '_', index));
    }

    function _validateClaim(bytes32[] memory claim, bytes32 leaf)
        internal
        view
        returns (bool)
    {
        return claim.verify(_masterClaim, leaf);
    }

    function _incrementClaimIndex(address wallet, uint256 count) internal {
        _nextClaimIndex[wallet] += count;
    }
}
