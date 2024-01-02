// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
import "./AccessControl.sol";

contract PermissionManager is AccessControl {

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(){
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    modifier onlyMinter() {
        _checkRole(MINTER_ROLE);
        _;
    }

    modifier onlyAdmin() {
        _checkRole(ADMIN_ROLE);
        _;
    }

    function grantRoleBatch(bytes32 role, address[] memory accounts) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            grantRole(role, account);
        }
    }

    function isMinter(address user) public view returns(bool){
        return hasRole(MINTER_ROLE, user);
    }

    function isAdmin(address user) public view returns(bool){
        return hasRole(ADMIN_ROLE, user);
    }
}
