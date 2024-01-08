//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

import "./IRolesManager.sol";
import "./RolesManagerConsts.sol";
import "./AccessControl.sol";

contract RolesManager is AccessControl, IRolesManager {
    address public override consts;

    uint8 public override maxMultiItems;

    constructor(uint8 initialMaxMultiItems) public {
        maxMultiItems = initialMaxMultiItems;

        consts = address(new RolesManagerConsts());

        // Setting the role admin for all the platform roles.
        _setRoleAdmin(_consts().OWNER_ROLE(), _consts().OWNER_ROLE());
        _setRoleAdmin(_consts().PAUSER_ROLE(), _consts().OWNER_ROLE());
        _setRoleAdmin(_consts().MINTER_ROLE(), _consts().OWNER_ROLE());
        _setRoleAdmin(_consts().CONFIGURATOR_ROLE(), _consts().OWNER_ROLE());

        // Setting roles
        /*
            The OWNER_ROLE is its own admin role. See AccessControl.DEFAULT_ADMIN_ROLE.
        */
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(_consts().OWNER_ROLE(), msg.sender);
        _setupRole(_consts().PAUSER_ROLE(), msg.sender);
        _setupRole(_consts().CONFIGURATOR_ROLE(), msg.sender);
        _setupRole(_consts().MINTER_ROLE(), msg.sender);
    }

    function requireHasRole(bytes32 role, address account) external view override {
        require(hasRole(role, account), "ACCOUNT_HASNT_GIVEN_ROLE");
    }

    function requireHasRole(
        bytes32 role,
        address account,
        string calldata message
    ) external view override {
        require(hasRole(role, account), message);
    }

    function setMaxMultiItems(uint8 newMaxMultiItems) external override {
        require(hasRole(_consts().OWNER_ROLE(), _msgSender()), "SENDER_HASNT_OWNER_ROLE");
        require(maxMultiItems != newMaxMultiItems, "NEW_MAX_MULTI_ITEMS_REQUIRED");
        uint8 oldMaxMultiItems = maxMultiItems;

        maxMultiItems = newMaxMultiItems;

        emit MaxMultiItemsUpdated(msg.sender, oldMaxMultiItems, newMaxMultiItems);
    }

    function multiGrantRole(bytes32 role, address[] calldata accounts) external override {
        require(accounts.length <= maxMultiItems, "ACCOUNTS_LENGTH_EXCEEDS_MAX");
        for (uint256 i = 0; i < accounts.length; i++) {
            grantRole(role, accounts[i]);
        }
    }

    function multiRevokeRole(bytes32 role, address[] calldata accounts) external override {
        require(accounts.length <= maxMultiItems, "ACCOUNTS_LENGTH_EXCEEDS_MAX");

        for (uint256 i = 0; i < accounts.length; i++) {
            revokeRole(role, accounts[i]);
        }
    }

    function setRoleAdmin(bytes32 role, bytes32 adminRole) external override {
        require(getRoleAdmin(role) == "", "ROLE_MUST_BE_NEW");
        require(hasRole(_consts().OWNER_ROLE(), _msgSender()), "SENDER_HASNT_OWNER_ROLE");

        _setRoleAdmin(role, adminRole);
    }

    function _consts() internal view returns (RolesManagerConsts) {
        return RolesManagerConsts(consts);
    }
}
