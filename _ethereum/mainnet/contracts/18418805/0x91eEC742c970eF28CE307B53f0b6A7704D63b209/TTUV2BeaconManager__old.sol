// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "./UpgradeableBeacon.sol";
import "./Ownable.sol";

/**
 * @title TTUV2BeaconManager
 * @author Jack Xu @ EthSign
 * @dev This contract manages the upgradeable beacons that we use to seamlessly
 * upgrade TokenTableUnlocker, TTFutureToken, and TTTrackerToken on behalf of
 * our users in the future.
 *
 * This contract should be deployed using TTUDeployer.
 */
contract TTUV2BeaconManager__old is Ownable {
    UpgradeableBeacon public immutable unlockerBeacon;
    UpgradeableBeacon public immutable futureTokenBeacon;
    UpgradeableBeacon public immutable trackerTokenBeacon;

    constructor(
        address unlockerImpl,
        address futureTokenImpl,
        address trackerTokenImpl
    ) {
        unlockerBeacon = new UpgradeableBeacon(unlockerImpl);
        futureTokenBeacon = new UpgradeableBeacon(futureTokenImpl);
        trackerTokenBeacon = new UpgradeableBeacon(trackerTokenImpl);
    }

    function upgradeUnlocker(address newImpl) external onlyOwner {
        unlockerBeacon.upgradeTo(newImpl);
    }

    function upgradeFutureToken(address newImpl) external onlyOwner {
        futureTokenBeacon.upgradeTo(newImpl);
    }

    function upgradePreviewToken(address newImpl) external onlyOwner {
        trackerTokenBeacon.upgradeTo(newImpl);
    }
}
