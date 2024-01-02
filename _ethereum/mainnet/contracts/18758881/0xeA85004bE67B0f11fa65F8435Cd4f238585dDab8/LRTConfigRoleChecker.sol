// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.21;

import "./UtilLib.sol";
import "./LRTConstants.sol";

import "./ILRTConfig.sol";

import "./IAccessControl.sol";

/// @title LRTConfigRoleChecker - LRT Config Role Checker Contract
/// @notice Handles LRT config role checks
abstract contract LRTConfigRoleChecker {
    ILRTConfig public lrtConfig;

    // events
    event UpdatedLRTConfig(address indexed lrtConfig);

    // modifiers
    modifier onlyRole(bytes32 role) {
        if (!IAccessControl(address(lrtConfig)).hasRole(role, msg.sender)) {
            string memory roleStr = string(abi.encodePacked(role));
            revert ILRTConfig.CallerNotLRTConfigAllowedRole(roleStr);
        }
        _;
    }

    modifier onlyLRTManager() {
        if (!IAccessControl(address(lrtConfig)).hasRole(LRTConstants.MANAGER, msg.sender)) {
            revert ILRTConfig.CallerNotLRTConfigManager();
        }
        _;
    }

    modifier onlyLRTAdmin() {
        if (!IAccessControl(address(lrtConfig)).hasRole(LRTConstants.DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert ILRTConfig.CallerNotLRTConfigAdmin();
        }
        _;
    }

    modifier onlySupportedAsset(address asset) {
        if (!lrtConfig.isSupportedAsset(asset)) {
            revert ILRTConfig.AssetNotSupported();
        }
        _;
    }

    // setters

    /// @notice Updates the LRT config contract
    /// @dev only callable by LRT admin
    /// @param lrtConfigAddr the new LRT config contract Address
    function updateLRTConfig(address lrtConfigAddr) external virtual onlyLRTAdmin {
        UtilLib.checkNonZeroAddress(lrtConfigAddr);
        lrtConfig = ILRTConfig(lrtConfigAddr);
        emit UpdatedLRTConfig(lrtConfigAddr);
    }
}
