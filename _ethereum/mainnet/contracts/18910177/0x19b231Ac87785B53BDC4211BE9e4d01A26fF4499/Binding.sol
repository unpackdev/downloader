// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.23;

import "./AccessControl.sol";
import "./IBinding.sol";

contract Binding is IBinding, AccessControl {

    bytes32 public constant CRYPTAR_ROLE = keccak256("CRYPTAR_ROLE");

    constructor() {
        // Assign the default admin role to the contract deployer
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier onlyAdmin() {
        _checkRole(DEFAULT_ADMIN_ROLE);
        _;
    }

    modifier onlyCryptar() {
        _checkRole(CRYPTAR_ROLE);
        _;
    }

    function bindCryptar(
        address cryptar
    ) external onlyAdmin {
        _grantRole(CRYPTAR_ROLE, cryptar);
    }

    function transferOwnership(
        address owner
    ) external onlyAdmin {
        if(owner == address(0)) revert InvalidTransferOwnership();
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
    }
}
