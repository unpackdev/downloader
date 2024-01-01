/*
  Copyright 2019-2023 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.8.0;

import "./AccessControl.sol";

// int.from_bytes(Web3.keccak(text="ROLE_APP_GOVERNOR"), "big") & MASK_250 .
bytes32 constant APP_GOVERNOR = bytes32(
    uint256(0xd2ead78c620e94b02d0a996e99298c59ddccfa1d8a0149080ac3a20de06068)
);

// int.from_bytes(Web3.keccak(text="ROLE_APP_ROLE_ADMIN"), "big") & MASK_250 .
bytes32 constant APP_ROLE_ADMIN = bytes32(
    uint256(0x03e615638e0b79444a70f8c695bf8f2a47033bf1cf95691ec3130f64939cee99)
);

// int.from_bytes(Web3.keccak(text="ROLE_GOVERNANCE_ADMIN"), "big") & MASK_250 .
bytes32 constant GOVERNANCE_ADMIN = bytes32(
    uint256(0x03711c9d994faf6055172091cb841fd4831aa743e6f3315163b06a122c841846)
);

// int.from_bytes(Web3.keccak(text="ROLE_OPERATOR"), "big") & MASK_250 .
bytes32 constant OPERATOR = bytes32(
    uint256(0x023edb77f7c8cc9e38e8afe78954f703aeeda7fffe014eeb6e56ea84e62f6da7)
);

// int.from_bytes(Web3.keccak(text="ROLE_TOKEN_ADMIN"), "big") & MASK_250 .
bytes32 constant TOKEN_ADMIN = bytes32(
    uint256(0x0128d63adbf6b09002c26caf55c47e2f26635807e3ef1b027218aa74c8d61a3e)
);

// int.from_bytes(Web3.keccak(text="ROLE_UPGRADE_GOVERNOR"), "big") & MASK_250 .
bytes32 constant UPGRADE_GOVERNOR = bytes32(
    uint256(0x0251e864ca2a080f55bce5da2452e8cfcafdbc951a3e7fff5023d558452ec228)
);

/*
  Role                |   Role Admin
  ----------------------------------------
  GOVERNANCE_ADMIN    |   GOVERNANCE_ADMIN
  UPGRADE_GOVERNOR    |   GOVERNANCE_ADMIN
  APP_ROLE_ADMIN      |   GOVERNANCE_ADMIN
  APP_GOVERNOR        |   APP_ROLE_ADMIN
  OPERATOR            |   APP_ROLE_ADMIN
  TOKEN_ADMIN         |   APP_ROLE_ADMIN.
*/
abstract contract Roles {
    // This flag dermine if the GOVERNANCE_ADMIN role can be renounced.
    bool immutable fullyRenouncable;

    constructor(bool renounceable) {
        fullyRenouncable = renounceable;
        initialize();
    }

    // INITIALIZERS.
    function rolesInitialized() internal view virtual returns (bool) {
        return AccessControl.getRoleAdmin(GOVERNANCE_ADMIN) != bytes32(0x00);
    }

    function initialize() internal {
        initialize(AccessControl._msgSender());
    }

    function initialize(address provisionalGovernor) internal {
        if (rolesInitialized()) {
            // Support Proxied contract initialization.
            // In case the Proxy already initialized the roles,
            // init will succeed IFF the provisionalGovernor is already `GovernanceAdmin`.
            require(isGovernanceAdmin(provisionalGovernor), "ALREADY_INITIALIZED");
        } else {
            AccessControl._grantRole(GOVERNANCE_ADMIN, provisionalGovernor);
            AccessControl._setRoleAdmin(APP_GOVERNOR, APP_ROLE_ADMIN);
            AccessControl._setRoleAdmin(APP_ROLE_ADMIN, GOVERNANCE_ADMIN);
            AccessControl._setRoleAdmin(GOVERNANCE_ADMIN, GOVERNANCE_ADMIN);
            AccessControl._setRoleAdmin(OPERATOR, APP_ROLE_ADMIN);
            AccessControl._setRoleAdmin(TOKEN_ADMIN, APP_ROLE_ADMIN);
            AccessControl._setRoleAdmin(UPGRADE_GOVERNOR, GOVERNANCE_ADMIN);
        }
    }

    // MODIFIERS.
    modifier onlyAppGovernor() {
        require(isAppGovernor(AccessControl._msgSender()), "ONLY_APP_GOVERNOR");
        _;
    }

    modifier onlyAppRoleAdmin() {
        require(isAppRoleAdmin(AccessControl._msgSender()), "ONLY_APP_ROLE_ADMIN");
        _;
    }

    modifier onlyGovernanceAdmin() {
        require(isGovernanceAdmin(AccessControl._msgSender()), "ONLY_GOVERNANCE_ADMIN");
        _;
    }

    modifier onlyOperator() {
        require(isOperator(AccessControl._msgSender()), "ONLY_OPERATOR");
        _;
    }

    modifier onlyTokenAdmin() {
        require(isTokenAdmin(AccessControl._msgSender()), "ONLY_TOKEN_ADMIN");
        _;
    }

    modifier onlyUpgradeGovernor() {
        require(isUpgradeGovernor(AccessControl._msgSender()), "ONLY_UPGRADE_GOVERNOR");
        _;
    }

    modifier notSelf(address account) {
        require(account != AccessControl._msgSender(), "CANNOT_PERFORM_ON_SELF");
        _;
    }

    // Is holding role.
    function isAppGovernor(address account) public view returns (bool) {
        return AccessControl.hasRole(APP_GOVERNOR, account);
    }

    function isAppRoleAdmin(address account) public view returns (bool) {
        return AccessControl.hasRole(APP_ROLE_ADMIN, account);
    }

    function isGovernanceAdmin(address account) public view returns (bool) {
        return AccessControl.hasRole(GOVERNANCE_ADMIN, account);
    }

    function isOperator(address account) public view returns (bool) {
        return AccessControl.hasRole(OPERATOR, account);
    }

    function isTokenAdmin(address account) public view returns (bool) {
        return AccessControl.hasRole(TOKEN_ADMIN, account);
    }

    function isUpgradeGovernor(address account) public view returns (bool) {
        return AccessControl.hasRole(UPGRADE_GOVERNOR, account);
    }

    // Register Role.
    function registerAppGovernor(address account) external {
        AccessControl.grantRole(APP_GOVERNOR, account);
    }

    function registerAppRoleAdmin(address account) external {
        AccessControl.grantRole(APP_ROLE_ADMIN, account);
    }

    function registerGovernanceAdmin(address account) external {
        AccessControl.grantRole(GOVERNANCE_ADMIN, account);
    }

    function registerOperator(address account) external {
        AccessControl.grantRole(OPERATOR, account);
    }

    function registerTokenAdmin(address account) external {
        AccessControl.grantRole(TOKEN_ADMIN, account);
    }

    function registerUpgradeGovernor(address account) external {
        AccessControl.grantRole(UPGRADE_GOVERNOR, account);
    }

    // Revoke Role.
    function revokeAppGovernor(address account) external {
        AccessControl.revokeRole(APP_GOVERNOR, account);
    }

    function revokeAppRoleAdmin(address account) external notSelf(account) {
        AccessControl.revokeRole(APP_ROLE_ADMIN, account);
    }

    function revokeGovernanceAdmin(address account) external notSelf(account) {
        AccessControl.revokeRole(GOVERNANCE_ADMIN, account);
    }

    function revokeOperator(address account) external {
        AccessControl.revokeRole(OPERATOR, account);
    }

    function revokeTokenAdmin(address account) external {
        AccessControl.revokeRole(TOKEN_ADMIN, account);
    }

    function revokeUpgradeGovernor(address account) external {
        AccessControl.revokeRole(UPGRADE_GOVERNOR, account);
    }

    // Renounce Role.
    function renounceRole(bytes32 role, address account) external {
        if (role == GOVERNANCE_ADMIN && !fullyRenouncable) {
            revert("CANNOT_RENOUNCE_GOVERNANCE_ADMIN");
        }
        AccessControl.renounceRole(role, account);
    }
}
