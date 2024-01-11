// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AdminControl.sol";
import "./MerkleProof.sol";

/**
 * A merkle tree based allowlist
 */

abstract contract Allowlist is AdminControl {
    //
    // State
    //

    // the merkle root for the allowlist
    bytes32 public merkleRoot;

    // boolean to signal if the allowlist is enabled or not
    bool public allowlistEnabled;

    //
    // Internal API
    //

    /**
     * if the allowlist is enabled
     * check if the merkleProof is on the allowlist
     * and is valid for the msg.sender
     */
    function ifEnabledCheckAllowlist(bytes32[] calldata merkleProof)
        internal
        view
        returns (bool)
    {
        return !allowlistEnabled || isOnAllowlist(merkleProof);
    }

    /**
     * Check if a given merkleProof is on the allowlist
     * and is valid for the msg.sender
     */
    function isOnAllowlist(bytes32[] calldata merkleProof)
        internal
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            );
    }

    //
    // Queries
    //

    /**
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AdminControl)
        returns (bool)
    {
        return AdminControl.supportsInterface(interfaceId);
    }

    //
    // Admin required
    //

    /**
     * Toggle the allowlist on or off depending on its
     * current state
     */
    function toggleAllowlist() external adminRequired {
        allowlistEnabled = !allowlistEnabled;
    }

    /**
     * Set the merkleRoot
     */
    function setAllowlist(bytes32 _merkleRoot) external adminRequired {
        merkleRoot = _merkleRoot;
    }

    /**
     * set the allowlist on or off deterministically
     */
    function setAllowlistStatus(bool status) public adminRequired {
        allowlistEnabled = status;
    }
}
