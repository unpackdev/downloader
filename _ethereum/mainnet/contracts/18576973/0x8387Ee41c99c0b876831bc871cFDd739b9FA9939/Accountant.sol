// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./AddressUtils.sol";

import "./Registry.sol";
import "./RegistryStorage.sol";
import "./VaultBaseExternal.sol";
import "./IAggregatorV3Interface.sol";
import "./IValioCustomAggregator.sol";
import "./IValuer.sol";

import "./Constants.sol";

contract Accountant {
    using AddressUtils for address;

    Registry registry;

    constructor(address _registry) {
        require(_registry != address(0), 'Invalid registry');
        registry = Registry(_registry);
    }

    function isSupportedAsset(address asset) external view returns (bool) {
        return registry.valuers(asset) != address(0);
    }

    function isDeprecated(address asset) external view returns (bool) {
        return registry.deprecatedAssets(asset);
    }

    function isHardDeprecated(address asset) external view returns (bool) {
        return _isHardDeprecated(asset);
    }

    function getVaultValue(
        address vault
    )
        external
        view
        returns (uint minValue, uint maxValue, bool hasHardDeprecatedAsset)
    {
        address[] memory activeAssets = VaultBaseExternal(payable(vault))
            .assetsWithBalances();
        for (uint i = 0; i < activeAssets.length; i++) {
            if (_isHardDeprecated(activeAssets[i])) {
                hasHardDeprecatedAsset = true;
            }
            (uint minAssetValue, uint maxAssetValue) = _assetValueOfVault(
                activeAssets[i],
                vault
            );
            minValue += minAssetValue;
            maxValue += maxAssetValue;
        }
    }

    function assetValueOfVault(
        address asset,
        address vault
    ) external view returns (uint minValue, uint maxValue) {
        return _assetValueOfVault(asset, vault);
    }

    function assetIsActive(
        address asset,
        address vault
    ) external view returns (bool) {
        return _assetIsActive(asset, vault);
    }

    function assetValue(
        address asset,
        uint amount
    ) external view returns (uint minValue, uint maxValue) {
        int256 unitPrice = _getUSDPrice(asset);
        address valuer = registry.valuers(asset);
        require(valuer != address(0), 'No valuer');
        return IValuer(valuer).getAssetValue(amount, asset, unitPrice);
    }

    function assetBreakDownOfVault(
        address vault
    ) external view returns (IValuer.AssetValue[] memory) {
        address[] memory activeAssets = VaultBaseExternal(payable(vault))
            .assetsWithBalances();
        IValuer.AssetValue[] memory ava = new IValuer.AssetValue[](
            activeAssets.length
        );
        for (uint i = 0; i < activeAssets.length; i++) {
            // Hard deprecated assets have 0 value, but they can be traded out of
            bool hardDeprecated = registry.hardDeprecatedAssets(
                activeAssets[i]
            );

            int256 unitPrice = hardDeprecated
                ? int256(0)
                : _getUSDPrice(activeAssets[i]);
            address valuer = registry.valuers(activeAssets[i]);
            require(valuer != address(0), 'No valuer');
            ava[i] = IValuer(valuer).getAssetBreakdown(
                vault,
                activeAssets[i],
                unitPrice
            );
        }
        return ava;
    }

    function _assetValueOfVault(
        address asset,
        address vault
    ) internal view returns (uint minValue, uint maxValue) {
        // Hard deprecated assets have 0 value, but they can be traded out of
        if (registry.hardDeprecatedAssets(asset)) {
            return (0, 0);
        }
        int256 unitPrice = _getUSDPrice(asset);
        address valuer = registry.valuers(asset);
        require(valuer != address(0), 'No valuer');
        return IValuer(valuer).getVaultValue(vault, asset, unitPrice);
    }

    function _assetIsActive(
        address asset,
        address vault
    ) internal view returns (bool) {
        address valuer = registry.valuers(asset);
        require(valuer != address(0), 'No valuer');
        return IValuer(valuer).getAssetActive(vault, asset);
    }

    function _getUSDPrice(address asset) internal view returns (int256 price) {
        uint256 updatedAt;

        RegistryStorage.AggregatorType aggregatorType = registry
            .assetAggregatorType(asset);

        if (aggregatorType == RegistryStorage.AggregatorType.ChainlinkV3USD) {
            IAggregatorV3Interface chainlinkAggregator = registry
                .chainlinkV3USDAggregators(asset);
            require(
                address(chainlinkAggregator) != address(0),
                'No cl aggregator'
            );
            (, price, , updatedAt, ) = chainlinkAggregator.latestRoundData();
        } else if (
            aggregatorType == RegistryStorage.AggregatorType.UniswapV3Twap ||
            aggregatorType == RegistryStorage.AggregatorType.VelodromeV2Twap
        ) {
            IValioCustomAggregator valioAggregator = registry
                .valioCustomUSDAggregators(aggregatorType);

            require(address(valioAggregator) != address(0), 'No vl aggregator');
            (price, updatedAt) = valioAggregator.latestRoundData(asset);
        } else if (aggregatorType == RegistryStorage.AggregatorType.None) {
            return 0;
        } else {
            revert('Unsupported aggregator type');
        }

        require(
            updatedAt + registry.chainlinkTimeout() >= block.timestamp,
            'Price expired'
        );

        require(price > 0, 'Price not available');

        price = price * (int(Constants.VAULT_PRECISION) / 10 ** 8);
    }

    function _isHardDeprecated(address asset) internal view returns (bool) {
        return registry.hardDeprecatedAssets(asset);
    }
}
