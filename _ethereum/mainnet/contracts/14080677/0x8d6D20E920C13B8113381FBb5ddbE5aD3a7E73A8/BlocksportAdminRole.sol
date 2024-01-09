// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "./IAdminRole.sol";

import "./BlocksportTreasuryNode.sol";

/**
 * @notice Allows a contract to leverage an admin role defined by the Blocksport contract.
 */
abstract contract BlocksportAdminRole is BlocksportTreasuryNode {
    // This file uses 0 data slots (other than what's included via BlocksportTreasuryNode)

    modifier onlyBlocksportAdmin() {
        require(
            IAdminRole(getBlocksportTreasury()).isAdmin(msg.sender),
            "BlocksportAdminRole: caller does not have the Admin role"
        );
        _;
    }
}
