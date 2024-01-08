// SPDX-License-Identifier: MIT
pragma solidity ^0.6.8;

import "./AccessControl.sol";


contract Roles is AccessControl {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER"); // "f0887ba65ee2024ea881d91b74c2450ef19e1557f03bed3ea9f16b037cbe2dc9"; // 
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR"); // "523a704056dcd17bcf83bed8b68c59416dac1119be77755efe3bde0a64e46e0c"; // 

    constructor () public {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(OPERATOR_ROLE, _msgSender());
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "Roles: caller does not have the MINTER role");
        _;
    }

    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, _msgSender()), "Roles: caller does not have the OPERATOR role");
        _;
    }
}