// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import "./DappMods.sol";
import "./PausableMods.sol";
import "./ChainlinkPricer.sol";

// Storage
import "./app.sol";

abstract contract AbstractSwapper is PausableMods, DappMods {
    function __isValidPath(address src, address dst) internal returns (bool) {
        ChainlinkPricer chainlinkPricer = AppStorageLib
            .store()
            .priceAggregator
            .chainlinkPricer();
        bool srcCheck = (src == AppStorageLib.store().wrappedNativeToken ||
            address(chainlinkPricer.getEthAggregator(src)) != address(0));
        bool dstCheck = (dst == AppStorageLib.store().wrappedNativeToken ||
            address(chainlinkPricer.getEthAggregator(dst)) != address(0));
        return srcCheck && dstCheck;
    }
}
