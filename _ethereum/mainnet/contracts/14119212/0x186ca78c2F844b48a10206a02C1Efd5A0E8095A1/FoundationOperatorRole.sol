// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

import "./IOperatorRole.sol";

import "./FoundationTreasuryNode.sol";

/**
 * @notice Allows a contract to leverage the operator role defined by the Foundation treasury.
 */
abstract contract FoundationOperatorRole is FoundationTreasuryNode {
    // This file uses 0 data slots (other than what's included via FoundationTreasuryNode)

    function _isFoundationOperator() internal view returns (bool) {
        return IOperatorRole(getFoundationTreasury()).isOperator(msg.sender);
    }
}