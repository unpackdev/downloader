// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import "./TellerNFT.sol";
import "./PriceAggregator.sol";

// Libraries
import "./PlatformSettingsLib.sol";
import "./CacheLib.sol";
import "./UpgradeableBeaconFactory.sol";

struct AppStorage {
    // is it initialized
    bool initialized;
    // is it platform restricted
    bool platformRestricted; // DEPRECATED
    // mapping between contract IDs and if they're paused
    mapping(bytes32 => bool) paused;
    //p
    mapping(bytes32 => PlatformSetting) platformSettings;
    mapping(address => Cache) assetSettings;
    mapping(string => address) _assetAddresses; // DEPRECATED
    mapping(address => bool) _cTokenRegistry; // DEPRECATED
    TellerNFT nft;
    UpgradeableBeaconFactory loansEscrowBeacon;
    UpgradeableBeaconFactory collateralEscrowBeacon;
    address nftLiquidationController;
    UpgradeableBeaconFactory tTokenBeacon;
    address wrappedNativeToken;
    PriceAggregator priceAggregator;
}

library AppStorageLib {
    function store() internal pure returns (AppStorage storage s) {
        assembly {
            s.slot := 0
        }
    }
}
