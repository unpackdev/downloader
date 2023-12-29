// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import "./IMauveFactoryReduced.sol";
import "./IVioletIDReduced.sol";
import "./PeripheryImmutableState.sol";

/// @title Mauve Compliance
/// @notice Defines extra rules for access control beyond what is provided by Violet EATs
abstract contract MauveCompliance is PeripheryImmutableState {
    IVioletIDReduced private immutable _violetID;
    bool public isEmergencyMode = false;

    constructor(address _violetId) {
        _violetID = IVioletIDReduced(_violetId);
    }

    modifier onlyFactoryOwner() {
        _checkFactoryOwner();
        _;
    }

    modifier onlyWhenNotEmergencyMode() {
        _checkIsNotInEmergencyMode();
        _;
    }

    modifier onlyAllowedToInteract(address from, address to) {
        _checkAllowedToInteract(from, to);
        _;
    }

    function setEmergencyMode(bool isEmergencyMode_) external onlyFactoryOwner {
        isEmergencyMode = isEmergencyMode_;
    }

    /// @dev Checks whether an address is allowed to interact with Mauve.
    // Used as an alternative to the EAT system, it verifies the compliance status of an account by
    // checking that it owns at least one of the "tokenIds" necessary to be allowed to interact.
    function _checkIfAllowedToInteract(address account) internal view virtual returns (bool) {
        uint256[] memory tokenIds = IMauveFactoryReduced(factory).getMauveTokenIdsAllowedToInteract();

        uint256 length = tokenIds.length;
        for (uint256 i = 0; i < length; ++i) {
            bool hasStatus = _violetID.hasStatus(account, uint8(tokenIds[i]));
            if (hasStatus) {
                return true;
            }
        }
        return false;
    }

    /// @dev Verifies that both the `from` and `to` addresses are allowed to interact with Mauve.
    function _checkAllowedToInteract(address from, address to) internal view {
        // NID -> No Violet ID
        require(_checkIfAllowedToInteract(from) && _checkIfAllowedToInteract(to), 'NID');
    }

    /// @dev Checks that `msg.sender` is the `factoryOwner`.
    function _checkFactoryOwner() internal view {
        address factoryOwner = IMauveFactoryReduced(factory).roles('owner');
        // NFO -> Not Factory Owner
        require(msg.sender == factoryOwner, 'NFO');
    }

    function _checkIsNotInEmergencyMode() internal view {
        // EMA -> Emergency Mode Activated
        require(!_isEmergencyModeActivated(), 'EMA');
    }

    function _isEmergencyModeActivated() internal view returns (bool) {
        return isEmergencyMode;
    }
}
