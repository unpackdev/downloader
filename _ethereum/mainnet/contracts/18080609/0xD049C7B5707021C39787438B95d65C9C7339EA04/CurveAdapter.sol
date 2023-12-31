// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./ICurvePool.sol";
import "./uint16a16Lib.sol";

abstract contract Curve3CoinPoolAdapter {
    using uint16a16Lib for uint16a16;

    uint256 constant N_COINS = 3;

    function _addLiquidity(uint256[] memory amounts, uint256 slippage) internal {
        uint256[N_COINS] memory curveAmounts;

        for (uint256 i; i < amounts.length; ++i) {
            curveAmounts[assetMapping().get(i)] = amounts[i];
        }

        ICurve3CoinPool(pool()).add_liquidity(curveAmounts, slippage);
    }

    function _removeLiquidity(uint256 lpTokens, uint256[] calldata slippages, uint256 slippageOffset) internal {
        uint256[N_COINS] memory curveSlippages;

        for (uint256 i; i < N_COINS; ++i) {
            curveSlippages[assetMapping().get(i)] = slippages[slippageOffset + i];
        }

        ICurve3CoinPool(pool()).remove_liquidity(lpTokens, curveSlippages);
    }

    function pool() public view virtual returns (address);

    function assetMapping() public view virtual returns (uint16a16);
}

abstract contract CurveMetaPoolAdapter {
    uint256 constant N_COINS_META = 2;
    int128 immutable coinIndexBase;

    constructor(int128 coinIndexBase_) {
        coinIndexBase = coinIndexBase_;
    }

    function _addLiquidityMeta(uint256 baseAmount, uint256 extraAmount, uint256 slippage) internal {
        ICurve2CoinPool(poolMeta()).add_liquidity([extraAmount, baseAmount], slippage);
    }

    function _removeLiquidityBase(uint256 lpTokens, uint256 slippage) internal {
        ICurve2CoinPool(poolMeta()).remove_liquidity_one_coin(lpTokens, coinIndexBase, slippage);
    }

    function _calcWithdrawBase(uint256 burnAmount) internal view returns (uint256) {
        return ICurve2CoinPool(poolMeta()).calc_withdraw_one_coin(burnAmount, coinIndexBase);
    }

    function poolMeta() public view virtual returns (address);
}

abstract contract CurveUint256PoolAdapter {
    using uint16a16Lib for uint16a16;

    function _coins(uint256 index) internal view returns (address) {
        return ICurvePoolUint256(pool()).coins(assetMapping().get(index));
    }

    function _balances(uint256 index) internal view returns (uint256) {
        return ICurvePoolUint256(pool()).balances(assetMapping().get(index));
    }

    function pool() public view virtual returns (address);

    function assetMapping() public view virtual returns (uint16a16);
}
