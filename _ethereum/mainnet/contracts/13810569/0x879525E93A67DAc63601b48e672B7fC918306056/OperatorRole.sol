// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity 0.8.4;

import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";

/**
 * @notice Wraps a role from OpenZeppelin's AccessControl for easy integration.
 */
abstract contract OperatorRole is Initializable, AccessControlUpgradeable {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    function isOperator(address account) public view returns (bool) {
        return hasRole(OPERATOR_ROLE, account);
    }

    /**
     * @dev onlyOperator is enforced by `grantRole`.
     */
    function grantOperator(address account) public {
        grantRole(OPERATOR_ROLE, account);
    }

    /**
     * @dev onlyOperator is enforced by `revokeRole`.
     */
    function revokeOperator(address account) public {
        revokeRole(OPERATOR_ROLE, account);
    }
}
