// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity 0.8.4;

import "./IAdminRole.sol";

import "./WethioTreasuryNode.sol";

/**
 * @notice Allows a contract to leverage the admin role defined by the Wethio treasury.
 */
abstract contract WethioAdminRole is WethioTreasuryNode {
    // This file uses 0 data slots (other than what's included via WethioTreasuryNode)

    modifier onlyWethioAdmin() {
        require(
            _isWethioAdmin(),
            "WethioAdminRole: caller does not have the Admin role"
        );
        _;
    }

    function _isWethioAdmin() internal view returns (bool) {
        return IAdminRole(getWethioTreasury()).isAdmin(msg.sender);
    }
}
