// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./AccessControl.sol";

import "./Errors.sol";

import "./Constants.sol";
import "./IPrimexRegistry.sol";

contract PrimexRegistry is IPrimexRegistry, AccessControl {
    constructor() {
        _grantRole(BIG_TIMELOCK_ADMIN, msg.sender);
        // MEDIUM_TIMELOCK_ADMIN is admin for SMALL_TIMELOCK_ADMIN
        _setRoleAdmin(SMALL_TIMELOCK_ADMIN, MEDIUM_TIMELOCK_ADMIN);
        // SMALL_TIMELOCK_ADMIN is admin for EMERGENCY_ADMIN
        _setRoleAdmin(EMERGENCY_ADMIN, SMALL_TIMELOCK_ADMIN);
        // BIG_TIMELOCK_ADMIN is admin for other roles
    }

    /**
     * @inheritdoc IPrimexRegistry
     */
    mapping(bytes32 => bool) public override isRoleForContractsOnly;

    function setRoleAdmin(bytes32 role, bytes32 adminRole) external override onlyRole(BIG_TIMELOCK_ADMIN) {
        _setRoleAdmin(role, adminRole);
    }

    /**
     * @inheritdoc IPrimexRegistry
     */
    function setRolesForContractsOnly(bytes32[] calldata roles) external override onlyRole(BIG_TIMELOCK_ADMIN) {
        for (uint256 i; i < roles.length; i++) {
            isRoleForContractsOnly[roles[i]] = true;
        }
    }

    /**
     * @inheritdoc IPrimexRegistry
     */
    function removeRolesForContractsOnly(bytes32[] calldata roles) external override onlyRole(BIG_TIMELOCK_ADMIN) {
        for (uint256 i; i < roles.length; i++) {
            isRoleForContractsOnly[roles[i]] = false;
        }
    }

    function grantRole(bytes32 role, address account) public override(AccessControl, IPrimexRegistry) {
        if (isRoleForContractsOnly[role]) {
            _require(account.code.length > 0, Errors.ADDRESS_IS_NOT_CONTRACT.selector);
        }
        super.grantRole(role, account);
    }
}
