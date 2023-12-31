// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// OZ Libraries
import "./Ownable.sol";

// Local References
import "./OwnableDeferral.sol";

// Error Codes
error CallerIsNotOwner();

/**
 * @title OwnableDeferralResolution
 * @author @NiftyMike | @NFTCulture
 * @dev Implements checks for contract admin (Owner) operations. Backed by OZ Ownable.
 *
 * Ownership is assigned to contract deployer wallet by default.
 *
 * NOTE: IMPORTANT - This resolution will work great in a simple inheritance situation,
 * however, if multiple inheritance is involved, it might not adequately satisfy
 * override (...) conditions. In those scenarios, this code should be used as a
 * starting point and then adjusted appropriately.
 */
contract OwnableDeferralResolution is Ownable, OwnableDeferral {
    modifier isOwner() override {
        _isOwner();
        _;
    }

    function _isOwner() internal view override {
        // Same as _checkOwner() but using error code instead of a require statement.
        if (owner() != _msgSender()) revert CallerIsNotOwner();
    }
}
