// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import "./TellerNFT.sol";

// Interfaces

// Libraries
import "./PlatformSettingsLib.sol";
import "./CacheLib.sol";
import "./UpgradeableBeaconFactory.sol";

struct AppStorage {
    bool initialized;
    bool platformRestricted;
    mapping(bytes32 => bool) paused;
    mapping(bytes32 => PlatformSetting) platformSettings;
    mapping(address => Cache) assetSettings;
    mapping(string => address) assetAddresses;
    mapping(address => bool) cTokenRegistry;
    TellerNFT nft;
    UpgradeableBeaconFactory loansEscrowBeacon;
    UpgradeableBeaconFactory collateralEscrowBeacon;
    address nftLiquidationController;
    UpgradeableBeaconFactory tTokenBeacon;
}

library AppStorageLib {
    function store() internal pure returns (AppStorage storage s) {
        assembly {
            s.slot := 0
        }
    }
}
