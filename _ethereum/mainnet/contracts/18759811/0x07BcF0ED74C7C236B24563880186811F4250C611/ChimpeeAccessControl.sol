// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "./AccessControl.sol";

contract ChimpeeAccessControl is AccessControl {
    bytes32 public constant MINTER_ROLE =
        0x4d494e5445525f524f4c45000000000000000000000000000000000000000000;
    bytes32 public constant PAUSER_ROLE =
        0x5041555345525f524f4c45000000000000000000000000000000000000000000;

    constructor(address admin, address minter, address pauser) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, minter);
        _grantRole(PAUSER_ROLE, pauser);
    }

    modifier onlyMinter() {
        if (!hasRole(MINTER_ROLE, msg.sender)) {
            revert AccessControlUnauthorizedAccount(msg.sender, MINTER_ROLE);
        }
        _;
    }

    modifier onlyPauser() {
        if (!hasRole(PAUSER_ROLE, msg.sender)) {
            revert AccessControlUnauthorizedAccount(msg.sender, PAUSER_ROLE);
        }
        _;
    }

    modifier onlyAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert AccessControlUnauthorizedAccount(
                msg.sender,
                DEFAULT_ADMIN_ROLE
            );
        }
        _;
    }
}
