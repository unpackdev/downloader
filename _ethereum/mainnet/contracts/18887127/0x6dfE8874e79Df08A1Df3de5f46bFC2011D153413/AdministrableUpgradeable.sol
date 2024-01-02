// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControlEnumerableUpgradeable.sol";

abstract contract AdministrableUpgradeable is
    AccessControlEnumerableUpgradeable
{
    // AccessControl DEFAULT_ADMIN_ROLE = 0x00
    bytes32 public constant ADMIN_ROLE = 0x00;

    function _onlyAdmin(address account) internal view {
        require(
            hasRole(ADMIN_ROLE, account),
            "58" // 0x58	invalid operator (transfer agent)
        );
    }

    uint256[50] private __gap;
}
