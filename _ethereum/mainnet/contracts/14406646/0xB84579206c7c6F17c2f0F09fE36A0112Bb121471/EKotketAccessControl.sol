// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import "./AccessControlEnumerable.sol";
import "./Context.sol";

contract EKotketAccessControl is Context, AccessControlEnumerable {
    bytes32 public constant SC_MINTER_ROLE = keccak256("SC_MINTER_ROLE");
    bytes32 public constant SC_GATEWAY_ORACLE_ROLE = keccak256("SC_GATEWAY_ORACLE_ROLE");
    
    modifier onlyGatewayOraclePermission() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || hasRole(SC_GATEWAY_ORACLE_ROLE, _msgSender()), "Dont have Gateway Oracle permission!");
        _;
    } 

    modifier onlyMinterPermission() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || hasRole(SC_MINTER_ROLE, _msgSender()), "Dont have Minter permission!");
        _;
    } 

    modifier onlyAdminPermission() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Dont have Admin permission!");
        _;
    }

}