// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./AccessControl.sol";

import "./BaseContractRoles.sol";

contract ContractRoles is BaseContractRoles, AccessControl {
    error ZeroAddress();
    error NoPermission();

    constructor(address _adminWallet) {
        if (_adminWallet == address(0)) revert ZeroAddress();
        _grantRole(DEFAULT_ADMIN_ROLE, _adminWallet);
    }

    /**
     * @notice Reverts is msg sender does not equal address param and sender has not role param
     *
     * @param _player the address of the player verify
     * @param _role the role to verify
     */
    modifier onlySelfOrRole(address _player, bytes32 _role) {
        if (_player != _msgSender() && !hasRole(_role, _msgSender()))
            revert NoPermission();
        _;
    }
}
