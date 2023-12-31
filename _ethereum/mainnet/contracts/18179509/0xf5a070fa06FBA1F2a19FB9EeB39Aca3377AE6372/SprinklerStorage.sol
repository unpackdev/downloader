// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ICustomOracle.sol";

/// WhitelistAsset stores multiplier for exchange for each token
/// Whitelisted asset exchanges can be paused by setting isListed to false

struct WhitelistAsset {
    uint256 tokenMultiplier;
    bool isListed;
}

library SprinklerStorage {
    struct Layout {
        /// stores all whitelist token addresses
        address[] allWhiteList;
        mapping(address => WhitelistAsset) whitelistAssets;
        /// water amount available for sprinkler
        uint256 availableWater;
        /// swapped amount - withdran amount
        mapping(address => uint256) reserves;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("irrigation.contracts.storage.Sprinkler");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
