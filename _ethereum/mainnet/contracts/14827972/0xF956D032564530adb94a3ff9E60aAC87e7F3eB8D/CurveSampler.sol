// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./ICurve.sol";

interface CurvePool {
    function get_dy_underlying(
        int128,
        int128,
        uint256
    ) external view returns (uint256);

    function get_dy(
        int128,
        int128,
        uint256
    ) external view returns (uint256);
}

interface CryptoPool {
    function get_dy_underlying(
        uint256,
        uint256,
        uint256
    ) external view returns (uint256);

    function get_dy(
        uint256,
        uint256,
        uint256
    ) external view returns (uint256);
}

interface CryptoRegistry {
    function get_coin_indices(
        address pool,
        address from,
        address to
    ) external view returns (uint256, uint256);
}

interface CurveRegistry {
    function get_coin_indices(
        address pool,
        address from,
        address to
    )
        external
        view
        returns (
            int128,
            int128,
            bool
        );
}

contract CurveSampler {
    /// @dev Information for sampling from curve sources.

    /// @dev Base gas limit for Curve calls. Some Curves have multiple tokens
    ///      So a reasonable ceil is 150k per token. Biggest Curve has 4 tokens.
    uint256 private constant CURVE_CALL_GAS = 2000e3; // Was 600k for Curve but SnowSwap is using 1500k+
    address private constant CURVE_REGISTRY =
        0x90E00ACe148ca3b23Ac1bC8C240C2a7Dd9c2d7f5;
    address private constant CURVE_FACTORY =
        0xB9fC157394Af804a3578134A6585C0dc9cc990d4;
    address private constant CRYPTO_REGISTRY =
        0x8F942C20D02bEfc377D41445793068908E2250D0;
    address private constant CRYPTO_FACTORY =
        0xF18056Bbd320E96A48e3Fbf8bC061322531aac99;

    /// @dev Sample sell quotes from Curve.
    /// @param poolAddress Curve information specific to this token pair.
    /// @param fromToken Index of the taker token (what to sell).
    /// @param toToken Index of the maker token (what to buy).
    /// @param takerTokenAmounts Taker token sell amount for each sample.
    /// @return makerTokenAmounts Maker amounts bought at each taker token
    ///         amount.
    function sampleSellsFromCurve(
        address poolAddress,
        address fromToken,
        address toToken,
        uint256[] memory takerTokenAmounts
    ) public view returns (uint256[] memory makerTokenAmounts) {
        uint256 numSamples = takerTokenAmounts.length;
        makerTokenAmounts = new uint256[](numSamples);
        for (uint256 i = 0; i < numSamples; i++) {
            (
                uint256 fromTokenIdx,
                uint256 toTokenIdx,
                bool useUnderlying
            ) = getCoinIndices(poolAddress, fromToken, toToken);
            bytes4 selector;
            bytes4 selectorV2;
            if (useUnderlying) {
                selector = CurvePool.get_dy_underlying.selector;
                selectorV2 = CryptoPool.get_dy_underlying.selector;
            } else {
                selector = CurvePool.get_dy.selector;
                selectorV2 = CryptoPool.get_dy.selector;
            }
            uint256 buyAmount = 0;
            if (useUnderlying) {
                buyAmount = getBuyAmountUnderlying(
                    poolAddress,
                    fromTokenIdx,
                    toTokenIdx,
                    takerTokenAmounts[i]
                );
            } else {
                buyAmount = getBuyAmount(
                    poolAddress,
                    fromTokenIdx,
                    toTokenIdx,
                    takerTokenAmounts[i]
                );
            }

            makerTokenAmounts[i] = buyAmount;
            // Break early if there are 0 amounts
            if (makerTokenAmounts[i] == 0) {
                break;
            }
        }
    }

    function getCoinIndices(
        address poolAddress,
        address fromToken,
        address toToken
    )
        internal
        view
        returns (
            uint256 fromTokenIdx,
            uint256 toTokenIdx,
            bool useUnderlying
        )
    {
        useUnderlying = false;
        // getinfo from registry or factory
        (bool success0, bytes memory resultDatas0) = CURVE_REGISTRY.staticcall(
            abi.encodeWithSelector(
                CurveRegistry.get_coin_indices.selector,
                poolAddress,
                fromToken,
                toToken
            )
        );
        (bool success1, bytes memory resultDatas1) = CURVE_FACTORY.staticcall(
            abi.encodeWithSelector(
                CurveRegistry.get_coin_indices.selector,
                poolAddress,
                fromToken,
                toToken
            )
        );
        (bool success2, bytes memory resultDatas2) = CRYPTO_REGISTRY.staticcall(
            abi.encodeWithSelector(
                CryptoRegistry.get_coin_indices.selector,
                poolAddress,
                fromToken,
                toToken
            )
        );
        (bool success3, bytes memory resultDatas3) = CRYPTO_FACTORY.staticcall(
            abi.encodeWithSelector(
                CryptoRegistry.get_coin_indices.selector,
                poolAddress,
                fromToken,
                toToken
            )
        );
        if (success0) {
            (
                int128 _fromTokenIdx,
                int128 _toTokenIdx,
                bool _useUnderlying
            ) = abi.decode(resultDatas0, (int128, int128, bool));
            fromTokenIdx = uint256(int256(_fromTokenIdx));
            toTokenIdx = uint256(int256(_toTokenIdx));
            useUnderlying = _useUnderlying;
        } else if (success1) {
            (
                int128 _fromTokenIdx,
                int128 _toTokenIdx,
                bool _useUnderlying
            ) = abi.decode(resultDatas1, (int128, int128, bool));
            fromTokenIdx = uint256(int256(_fromTokenIdx));
            toTokenIdx = uint256(int256(_toTokenIdx));
            useUnderlying = _useUnderlying;
        } else if (success2) {
            (fromTokenIdx, toTokenIdx) = abi.decode(
                resultDatas2,
                (uint256, uint256)
            );
        } else {
            require(success3, "getCoinIndices Error");
            (fromTokenIdx, toTokenIdx) = abi.decode(
                resultDatas3,
                (uint256, uint256)
            );
        }
    }

    function getBuyAmount(
        address poolAddress,
        uint256 fromTokenIdx,
        uint256 toTokenIdx,
        uint256 sellAmount
    ) internal view returns (uint256 buyAmount) {
        try
            CryptoPool(poolAddress).get_dy(fromTokenIdx, toTokenIdx, sellAmount)
        returns (uint256 _buyAmount) {
            buyAmount = _buyAmount;
        } catch {
            int128 _fromTokenIdx = int128(int256(fromTokenIdx));
            int128 _toTokenIdx = int128(int256(toTokenIdx));
            buyAmount = CurvePool(poolAddress).get_dy(
                _fromTokenIdx,
                _toTokenIdx,
                sellAmount
            );
        }
    }

    function getBuyAmountUnderlying(
        address poolAddress,
        uint256 fromTokenIdx,
        uint256 toTokenIdx,
        uint256 sellAmount
    ) internal view returns (uint256 buyAmount) {
        try
            CryptoPool(poolAddress).get_dy_underlying(
                fromTokenIdx,
                toTokenIdx,
                sellAmount
            )
        returns (uint256 _buyAmount) {
            buyAmount = _buyAmount;
        } catch {
            int128 _fromTokenIdx = int128(int256(fromTokenIdx));
            int128 _toTokenIdx = int128(int256(toTokenIdx));
            buyAmount = CurvePool(poolAddress).get_dy_underlying(
                _fromTokenIdx,
                _toTokenIdx,
                sellAmount
            );
        }
    }
}
