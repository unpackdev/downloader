// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./DefinitiveAssets.sol";

import "./BaseTransfers.sol";
import "./DefinitiveErrors.sol";
import "./ConvexBase.sol";
import "./ICurveBase.sol";
import "./ConvexHelper.sol";
import "./LPStakingStrategy.sol";
import "./ConvexNoConvexRewarder.sol";

contract ConvexPrismaStrategy is BaseTransfers, ConvexNoConvexRewarder {
    using DefinitiveAssets for IERC20;

    constructor(
        CoreAccessControlConfig memory coreAccessControlConfig,
        CoreSwapConfig memory coreSwapConfig,
        CoreFeesConfig memory coreFeesConfig,
        LPStakingConfig memory lpConfig,
        ConvexConfig memory strategyConfig
    ) ConvexNoConvexRewarder(coreAccessControlConfig, coreSwapConfig, coreFeesConfig, lpConfig, strategyConfig) {
        rewardTokensStorage = new IERC20[](3);

        rewardTokensStorage[0] = IERC20(0xdA47862a83dac0c112BA89c6abC2159b95afd71C);
        rewardTokensStorage[1] = IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
        rewardTokensStorage[2] = IERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    }

    // Takes funds in contract and deposits into CRV
    function _addLiquidity(uint256[] calldata amounts, uint256 minAmount) internal override {
        uint256 mLP_UNDERLYING_TOKENS_COUNT = LP_UNDERLYING_TOKENS_COUNT;
        address[] memory mLP_UNDERLYING_TOKENS = LP_UNDERLYING_TOKENS;
        address mLP_TOKEN = LP_TOKEN;
        for (uint256 i; i < mLP_UNDERLYING_TOKENS_COUNT; ) {
            DefinitiveAssets.validateBalance(mLP_UNDERLYING_TOKENS[i], amounts[i]);
            IERC20(mLP_UNDERLYING_TOKENS[i]).resetAndSafeIncreaseAllowance(address(this), mLP_TOKEN, amounts[i]);
            unchecked {
                ++i;
            }
        }

        bool success = ConvexHelper.addCurveLiquidity(
            mLP_TOKEN,
            mLP_TOKEN,
            amounts,
            minAmount,
            cfg.isMetapool,
            mLP_UNDERLYING_TOKENS_COUNT
        );
        if (!success) {
            revert AddLiquidityFailed();
        }
    }

    // Removes LP tokens from Curve, needs to be made generic
    function _removeLiquidity(uint256 lpTokenAmount, uint256[] calldata minAmounts) internal override {
        address mLP_TOKEN = LP_TOKEN;
        DefinitiveAssets.validateBalance(mLP_TOKEN, lpTokenAmount);
        bool success = ConvexHelper.removeCurveLiquidity(
            mLP_TOKEN,
            mLP_TOKEN,
            lpTokenAmount,
            minAmounts,
            cfg.isMetapool,
            LP_UNDERLYING_TOKENS_COUNT
        );

        if (!success) {
            revert RemoveLiquidityFailed();
        }
    }

    function _removeLiquidityOneCoin(uint256 lpTokenAmount, uint256 minAmount, uint8 index) internal override {
        address mLP_TOKEN = LP_TOKEN;
        DefinitiveAssets.validateBalance(mLP_TOKEN, lpTokenAmount);
        if (cfg.isMetapool) {
            ICurveBase(mLP_TOKEN).remove_liquidity_one_coin(
                mLP_TOKEN,
                lpTokenAmount,
                int128(uint128(index)),
                minAmount
            );
        } else {
            ICurveBase(mLP_TOKEN).remove_liquidity_one_coin(lpTokenAmount, int128(uint128(index)), minAmount);
        }
    }
}
