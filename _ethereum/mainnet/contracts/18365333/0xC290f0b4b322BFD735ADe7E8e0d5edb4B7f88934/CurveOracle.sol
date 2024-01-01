// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./ERC20.sol";
import "./Math.sol";
import "./IOracle.sol";
import "./ICurveProvider.sol";
import "./ICurveRegistry.sol";
import "./ICurveSwap.sol";
import "./OraclePrices.sol";

contract CurveOracle is IOracle {
    using OraclePrices for OraclePrices.Data;
    using Math for uint256;

    enum CurveRegistryType {
        MAIN_REGISTRY,
        METAPOOL_FACTORY,
        CRYPTOSWAP_REGISTRY,
        CRYPTOPOOL_FACTORY,
        METAREGISTRY,
        CRVUSD_PLAIN_POOLS,
        CURVE_TRICRYPTO_FACTORY
    }

    struct FunctionInfo {
        bytes4 balanceFuncSelector;
        bytes4 dyFuncInt128Selector;
        function (uint256, uint256, uint256) external view returns (uint256) dyFuncUint256;
    }

    IERC20 private constant _NONE = IERC20(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);

    uint256 public immutable MAX_POOLS;
    uint256 public immutable REGISTRIES_COUNT;
    ICurveRegistry[11] public registries;
    CurveRegistryType[11] public registryTypes;

    constructor(ICurveProvider _addressProvider, uint256 _maxPools, uint256[] memory _registryIds, CurveRegistryType[] memory _registryTypes) {
        MAX_POOLS = _maxPools;
        REGISTRIES_COUNT = _registryIds.length;
        unchecked {
            for (uint256 i = 0; i < REGISTRIES_COUNT; i++) {
                registries[i] = ICurveRegistry(_addressProvider.get_address(_registryIds[i]));
                registryTypes[i] = _registryTypes[i];
            }
        }
    }

    function getRate(IERC20 srcToken, IERC20 dstToken, IERC20 connector, uint256 thresholdFilter) external view override returns (uint256 rate, uint256 weight) {
        if(connector != _NONE) revert ConnectorShouldBeNone();

        OraclePrices.Data memory ratesAndWeights = OraclePrices.init(MAX_POOLS);
        FunctionInfo memory info;
        uint256 index = 0;
        for (uint256 i = 0; i < REGISTRIES_COUNT && index < MAX_POOLS; i++) {
            uint256 registryIndex = 0;
            address pool = registries[i].find_pool_for_coins(address(srcToken), address(dstToken), registryIndex);
            while (pool != address(0) && index < MAX_POOLS) {
                index++;
                // call `get_coin_indices` and set (srcTokenIndex, dstTokenIndex, isUnderlying) variables
                bool isUnderlying;
                int128 srcTokenIndex;
                int128 dstTokenIndex;
                (bool success, bytes memory data) = address(registries[i]).staticcall(abi.encodeWithSelector(ICurveRegistry.get_coin_indices.selector, pool, address(srcToken), address(dstToken)));
                if (success && data.length >= 64) {
                    if (
                        registryTypes[i] == CurveRegistryType.CRYPTOSWAP_REGISTRY ||
                        registryTypes[i] == CurveRegistryType.CRYPTOPOOL_FACTORY ||
                        registryTypes[i] == CurveRegistryType.CURVE_TRICRYPTO_FACTORY
                    ) {
                        (srcTokenIndex, dstTokenIndex) = abi.decode(data, (int128, int128));
                    } else {
                        // registryTypes[i] == CurveRegistryType.MAIN_REGISTRY ||
                        // registryTypes[i] == CurveRegistryType.METAPOOL_FACTORY ||
                        // registryTypes[i] == CurveRegistryType.METAREGISTRY ||
                        // registryTypes[i] == CurveRegistryType.CRVUSD_PLAIN_POOLS
                        (srcTokenIndex, dstTokenIndex, isUnderlying) = abi.decode(data, (int128, int128, bool));
                    }
                } else {
                    pool = registries[i].find_pool_for_coins(address(srcToken), address(dstToken), ++registryIndex);
                    continue;
                }

                if (!isUnderlying) {
                    info = FunctionInfo({
                        balanceFuncSelector: ICurveRegistry.get_balances.selector,
                        dyFuncInt128Selector: ICurveSwapInt128.get_dy.selector,
                        dyFuncUint256: ICurveSwapUint256(pool).get_dy
                    });
                } else {
                    info = FunctionInfo({
                        balanceFuncSelector: ICurveRegistry.get_underlying_balances.selector,
                        dyFuncInt128Selector: ICurveSwapInt128.get_dy_underlying.selector,
                        dyFuncUint256: ICurveSwapUint256(pool).get_dy_underlying
                    });
                }

                // call `balanceFunc` (`get_balances` or `get_underlying_balances`) and decode results
                uint256[] memory balances;
                (success, data) = address(registries[i]).staticcall(abi.encodeWithSelector(info.balanceFuncSelector, pool));
                if (success && data.length >= 64) {
                    // registryTypes[i] == CurveRegistryType.MAIN_REGISTRY ||
                    // registryTypes[i] == CurveRegistryType.CRYPTOSWAP_REGISTRY ||
                    // registryTypes[i] == CurveRegistryType.METAREGISTRY
                    uint256 length = 8;
                    if (registryTypes[i] == CurveRegistryType.METAPOOL_FACTORY ||
                        registryTypes[i] == CurveRegistryType.CRVUSD_PLAIN_POOLS) {
                        length = 4;
                    } else if (registryTypes[i] == CurveRegistryType.CURVE_TRICRYPTO_FACTORY) {
                        length = 3;
                    } else if (registryTypes[i] == CurveRegistryType.CRYPTOPOOL_FACTORY) {
                        length = 2;
                    }

                    assembly ("memory-safe") { // solhint-disable-line no-inline-assembly
                        balances := data
                        mstore(balances, length)
                    }
                } else {
                    pool = registries[i].find_pool_for_coins(address(srcToken), address(dstToken), ++registryIndex);
                    continue;
                }

                uint256 w = (balances[uint128(srcTokenIndex)] * balances[uint128(dstTokenIndex)]).sqrt();
                uint256 b0 = balances[uint128(srcTokenIndex)] / 10000;
                uint256 b1 = balances[uint128(dstTokenIndex)] / 10000;

                if (b0 != 0 && b1 != 0) {
                    (success, data) = pool.staticcall(abi.encodeWithSelector(info.dyFuncInt128Selector, srcTokenIndex, dstTokenIndex, b0));
                    if (success && data.length >= 32) { // vyper could return redundant bytes
                        b1 = abi.decode(data, (uint256));
                    } else {
                        b1 = info.dyFuncUint256(uint128(srcTokenIndex), uint128(dstTokenIndex), b0);
                    }
                    ratesAndWeights.append(OraclePrices.OraclePrice(Math.mulDiv(b1, 1e18, b0), w));
                }
                pool = registries[i].find_pool_for_coins(address(srcToken), address(dstToken), ++registryIndex);
            }
        }
        (rate, weight) = ratesAndWeights.getRateAndWeight(thresholdFilter);
    }
}
