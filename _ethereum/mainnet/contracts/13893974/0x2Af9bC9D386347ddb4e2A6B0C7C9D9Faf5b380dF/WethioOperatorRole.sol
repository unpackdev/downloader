// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity 0.8.4;

import "./IOperatorRole.sol";

import "./WethioTreasuryNode.sol";

/**
 * @notice Allows a contract to leverage the operator role defined by the Wethio treasury.
 */
abstract contract WethioOperatorRole is WethioTreasuryNode {
    // This file uses 0 data slots (other than what's included via WethioTreasuryNode)

    function _isWethioOperator() internal view returns (bool) {
        return IOperatorRole(getWethioTreasury()).isOperator(msg.sender);
    }
}
