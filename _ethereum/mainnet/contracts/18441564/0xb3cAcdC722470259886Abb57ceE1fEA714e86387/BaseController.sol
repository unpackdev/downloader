// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import "./Ownable.sol";
import "./OevShare.sol";

/**
 * @title BaseController providing the simplest possible controller logic to govern who can unlock the OEVShare.
 * @dev Custom Controllers can be created to provide more granular control over who can unlock the OEVShare.
 */

abstract contract BaseController is Ownable, OevShare {
    // these don't need to be public since they can be accessed via the accessor functions below.
    uint256 private lockWindow_ = 60; // The lockWindow in seconds.
    uint256 private maxTraversal_ = 10; // The maximum number of rounds to traverse when looking for historical data.

    mapping(address => bool) public unlockers;

    /**
     * @notice Enables the owner to set the unlocker status of an address. Once set, the address can unlock the OEVShare
     * and by calling unlockLatestValue as part of an MEV-share auction.
     * @param unlocker The address to set the unlocker status of.
     * @param allowed The unlocker status to set.
     */
    function setUnlocker(address unlocker, bool allowed) public onlyOwner {
        unlockers[unlocker] = allowed;

        emit UnlockerSet(unlocker, allowed);
    }

    /**
     * @notice Returns true if the caller is allowed to unlock the OEVShare.
     * @dev This implementation simply checks if the caller is in the unlockers mapping. Custom Controllers can override
     * this function to provide more granular control over who can unlock the OEVShare.
     * @param caller The address to check.
     * @param _lastUnlockTime The timestamp of the latest unlock to the OEVShare. Might be useful in verification.
     */
    function canUnlock(address caller, uint256 _lastUnlockTime) public view override returns (bool) {
        return unlockers[caller];
    }

    /**
     * @notice Enables the owner to set the lockWindow.
     * @dev If changing the lockWindow would cause OEVShare to return different data the permissioned actor must first
     * call unlockLatestValue through flashbots via eth_sendPrivateTransaction.
     * @param newLockWindow The lockWindow to set.
     */
    function setLockWindow(uint256 newLockWindow) public onlyOwner {
        (int256 currentAnswer, uint256 currentTimestamp) = internalLatestData();

        lockWindow_ = newLockWindow;

        // Compare OEVShare results so that change in lock window does not change returned data.
        (int256 newAnswer, uint256 newTimestamp) = internalLatestData();
        require(currentAnswer == newAnswer && currentTimestamp == newTimestamp, "Must unlock first");

        emit LockWindowSet(newLockWindow);
    }

    /**
     * @notice Enables the owner to set the maxTraversal.
     * @param newMaxTraversal The maxTraversal to set.
     */
    function setMaxTraversal(uint256 newMaxTraversal) public onlyOwner {
        maxTraversal_ = newMaxTraversal;

        emit MaxTraversalSet(newMaxTraversal);
    }

    /**
     * @notice Time window that bounds how long the permissioned actor has to call the unlockLatestValue function after
     * a new source update is posted. If the permissioned actor does not call unlockLatestValue within this window of a
     * new source price, the latest value will be made available to everyone without going through an MEV-Share auction.
     * @return lockWindow time in seconds.
     */
    function lockWindow() public view override returns (uint256) {
        return lockWindow_;
    }

    /**
     * @notice Max number of historical source updates to traverse when looking for a historic value in the past.
     * @return maxTraversal max number of historical source updates to traverse.
     */
    function maxTraversal() public view override returns (uint256) {
        return maxTraversal_;
    }
}
