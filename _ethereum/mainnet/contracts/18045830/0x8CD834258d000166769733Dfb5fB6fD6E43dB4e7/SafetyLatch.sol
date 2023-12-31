// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// Local References
import "./OwnableDeferral.sol";

// Error Codes
error DestructRevoked();
error DestructExpired();

/**
 * @title SafetyLatch
 * @author @NFTCulture
 * @dev Utility class to fulfill "killswitch" requirements from business people.
 * I named it "SafetyLatch" just be less negative. The intent of this class is to
 * prevent screw-ups and not to be used nefariously.
 *
 * KillSwitch is set to expire on either of the following conditions:
 *      1) A preconfigured block timestamp passes.
 *      2) If it is voluntarily released by the owner.
 *
 * Call canDestruct() to see if the window has closed.
 *
 * Implementing contract must actually perform whatever logic needs to be done on destruct.
 */
abstract contract SafetyLatch is OwnableDeferral {
    uint256 private immutable DESTRUCT_WINDOW_ENDS_AT;
    bool private REVOKE_DESTRUCT = false;

    constructor(uint256 windowEndBlock) {
        DESTRUCT_WINDOW_ENDS_AT = windowEndBlock;
    }

    function destructContract() external isOwner {
        if (REVOKE_DESTRUCT) revert DestructRevoked();
        if (block.number >= DESTRUCT_WINDOW_ENDS_AT) revert DestructExpired();

        _executeOnDestruct();
    }

    function revokeDestruct() external isOwner {
        REVOKE_DESTRUCT = true;
    }

    function canDestruct() external view returns (bool) {
        if (REVOKE_DESTRUCT || block.number >= DESTRUCT_WINDOW_ENDS_AT) {
            return false;
        }

        return true;
    }

    function _executeOnDestruct() internal virtual;
}
