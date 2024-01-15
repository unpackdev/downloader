// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./LibAggregatorStorage.sol";
import "./LibFeatureStorage.sol";
import "./LibOwnableStorage.sol";


contract MasterFeature {

    struct Method {
        bytes4 methodID;
        string methodName;
    }

    struct Feature {
        address feature;
        string name;
        Method[] methods;
    }

    modifier onlyOwner() {
        require(LibOwnableStorage.getStorage().owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function getMethodIDs() external view returns (uint256 count, bytes4[] memory methodIDs) {
        LibFeatureStorage.Storage storage stor = LibFeatureStorage.getStorage();
        return (stor.methodIDs.length, stor.methodIDs);
    }

    function getFeatureImpl(bytes4 methodID) external view returns (address impl) {
        return LibFeatureStorage.getStorage().featureImpls[methodID];
    }

    function getFeature(address featureAddr) public view returns (Feature memory feature) {
        LibFeatureStorage.Storage storage stor = LibFeatureStorage.getStorage();

        // Calculate feature.methods.length
        uint256 methodsLength = 0;
        for (uint256 i = 0; i < stor.methodIDs.length; ++i) {
            bytes4 methodID = stor.methodIDs[i];
            if (featureAddr == stor.featureImpls[methodID]) {
                ++methodsLength;
            }
        }

        // Set methodIs
        uint256 j = 0;
        Method[] memory methods = new Method[](methodsLength);
        for (uint256 i = 0; i < stor.methodIDs.length && j < methodsLength; ++i) {
            bytes4 methodID = stor.methodIDs[i];
            if (featureAddr == stor.featureImpls[methodID]) {
                methods[j] = Method(methodID, stor.methodNames[methodID]);
                ++j;
            }
        }

        feature.feature = featureAddr;
        feature.name = stor.featureNames[featureAddr];
        feature.methods = methods;
        return feature;
    }

    function getFeatureByMethodID(bytes4 methodID) external view returns (Feature memory feature) {
        LibFeatureStorage.Storage storage stor = LibFeatureStorage.getStorage();
        address featureAddr = stor.featureImpls[methodID];
        return getFeature(featureAddr);
    }

    function getFeatures() external view returns (
        uint256 featuresCount,
        address[] memory features,
        string[] memory names,
        uint256[] memory featureMethodsCount
    ) {
        LibFeatureStorage.Storage storage stor = LibFeatureStorage.getStorage();
        uint256[] memory methodsCount = new uint256[](stor.methodIDs.length);
        address[] memory addrs = new address[](stor.methodIDs.length);

        for (uint256 i = 0; i < stor.methodIDs.length; ++i) {
            bytes4 methodID = stor.methodIDs[i];
            address impl = stor.featureImpls[methodID];

            uint256 j = 0;
            while (j < featuresCount && impl != addrs[j]) {
                ++j;
            }
            if (j == featuresCount) {
                addrs[j] = impl;
                ++featuresCount;
            }

            ++methodsCount[j];
        }

        features = new address[](featuresCount);
        names = new string[](featuresCount);
        featureMethodsCount = new uint256[](featuresCount);
        for (uint256 i = 0; i < featuresCount; ++i) {
            features[i] = addrs[i];
            names[i] = stor.featureNames[addrs[i]];
            featureMethodsCount[i] = methodsCount[i];
        }
        return (featuresCount, features, names, featureMethodsCount);
    }

    function getMarket(uint256 marketId) external view returns (LibAggregatorStorage.Market memory) {
        return LibAggregatorStorage.getStorage().markets[marketId];
    }

    function getMarkets() external view returns (
        uint256 marketsCount,
        address[] memory proxies,
        bool[] memory isLibrary,
        bool[] memory isActive
    ) {
        LibAggregatorStorage.Market[] storage markets = LibAggregatorStorage.getStorage().markets;
        proxies = new address[](markets.length);
        isLibrary = new bool[](markets.length);
        isActive = new bool[](markets.length);
        for (uint256 i = 0; i < markets.length; i++) {
            proxies[i] = markets[i].proxy;
            isLibrary[i] = markets[i].isLibrary;
            isActive[i] = markets[i].isActive;
        }
        return (markets.length, proxies, isLibrary, isActive);
    }

    function addMarket(address proxy, bool isLibrary) external onlyOwner {
        LibAggregatorStorage.getStorage().markets.push(
            LibAggregatorStorage.Market(proxy, isLibrary, true)
        );
    }

    function setMarketProxy(uint256 marketId, address newProxy, bool isLibrary) external onlyOwner {
        LibAggregatorStorage.Market storage market = LibAggregatorStorage.getStorage().markets[marketId];
        market.proxy = newProxy;
        market.isLibrary = isLibrary;
    }

    function setMarketActive(uint256 marketId, bool isActive) external onlyOwner {
        LibAggregatorStorage.Market storage market = LibAggregatorStorage.getStorage().markets[marketId];
        market.isActive = isActive;
    }
}
