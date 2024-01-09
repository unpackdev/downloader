// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

import "./IAdminRole.sol";

import "./FoundationTreasuryNode.sol";

/**
 * @notice Allows a contract to leverage the admin role defined by the Foundation treasury.
 */
abstract contract FoundationAdminRole is FoundationTreasuryNode {
    // This file uses 0 data slots (other than what's included via FoundationTreasuryNode)

    modifier onlyFoundationAdmin() {
        require(_isFoundationAdmin(), "FoundationAdminRole: caller does not have the Admin role");
        _;
    }

    function _isFoundationAdmin() internal view returns (bool) {
        return IAdminRole(getFoundationTreasury()).isAdmin(msg.sender);
    }
}