// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IBlacklist.sol";
import "./AccessControl.sol";

contract Blacklist is IBlacklist, AccessControl{

    bytes32 public constant BLACKLISTED = keccak256("BLACKLISTED");

    constructor() {
        // Grant the contract deployer the default admin role: it will be able
        // to grant and revoke any roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function add(address account) public  override onlyRole(getRoleAdmin(BLACKLISTED)) returns(bool) {
        _grantRole(BLACKLISTED, account);
        emit AddedToBlacklist(account);
        return true;
    }

    function remove(address account) public override onlyRole(getRoleAdmin(BLACKLISTED)) returns(bool) {
        _revokeRole(BLACKLISTED, account);
        emit RemovedFromBlacklist(account);
        return true;
    }

    function isBlacklisted(address account) public view override returns(bool) {
       return hasRole(BLACKLISTED, account);  
    }

    //====================================================================================================

    // function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
    //     revert();
    // }
    // function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
    //     revert();
    // }
    // function renounceRole(bytes32 role, address account) public virtual override {
    //     revert();
    // }
}