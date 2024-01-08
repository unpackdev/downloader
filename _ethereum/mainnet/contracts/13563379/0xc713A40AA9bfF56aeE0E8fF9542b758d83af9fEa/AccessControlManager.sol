// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./AccessControl.sol";

contract AccessControlManager is AccessControl {
    
    bytes32 public constant CEO_ROLE = keccak256("CEO");
    bytes32 public constant CFO_ROLE = keccak256("CFO");
    bytes32 public constant COO_ROLE = keccak256("COO");

    constructor() AccessControl() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(CEO_ROLE, _msgSender());
        
        _setRoleAdmin(CEO_ROLE, CEO_ROLE);
        _setRoleAdmin(COO_ROLE, CEO_ROLE);
        _setRoleAdmin(CFO_ROLE, CEO_ROLE);
    }
}
