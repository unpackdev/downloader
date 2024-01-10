// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./AccessControl.sol";

contract AccessControlManager is AccessControl {
    
    string public constant REVOKE_ROLE_ERROR = "AccessControlManager: unable to revoke the given role";

    bytes32 public constant CEO_ROLE = keccak256("CEO");
    bytes32 public constant CFO_ROLE = keccak256("CFO");
    bytes32 public constant COO_ROLE = keccak256("COO");

    mapping(bytes32 => uint) private _roleCounters;

    constructor(address admin, address ceo, address coo, address cfo) AccessControl() {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(CEO_ROLE, ceo);
        _setupRole(COO_ROLE, coo);
        _setupRole(CFO_ROLE, cfo);

        _roleCounters[DEFAULT_ADMIN_ROLE] = 1;
        _roleCounters[CEO_ROLE] = 1;
        _roleCounters[COO_ROLE] = 1;
        _roleCounters[CFO_ROLE] = 1;
        
        _setRoleAdmin(COO_ROLE, CEO_ROLE);
        _setRoleAdmin(CFO_ROLE, CEO_ROLE);
    }

    function grantRole(bytes32 role, address account) public virtual override {
        if (!hasRole(role, account)) {
            _roleCounters[role]++;
        }
        super.grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public virtual override {
        if (hasRole(role, account)) {
            if (_roleCounters[role] == 1) {
                revert(REVOKE_ROLE_ERROR);
            } 
            _roleCounters[role]--;
        }
        super.revokeRole(role, account);
    }

    function renounceRole(bytes32 role, address account) public virtual override {
        if (hasRole(role, account)) {
            if (_roleCounters[role] == 1) {
                revert(REVOKE_ROLE_ERROR);
            }
            _roleCounters[role]--;
        }
        super.renounceRole(role, account);
    }
}
