// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./DefinitiveAssets.sol";
import "./LPStakingStrategy.sol";

struct ConvexConfig {
    address convexRewarder;
    bool isMetapool;
}

abstract contract ConvexBase is LPStakingStrategy {
    using DefinitiveAssets for IERC20;

    ConvexConfig public cfg;

    constructor(
        CoreAccessControlConfig memory coreAccessControlConfig,
        CoreSwapConfig memory coreSwapConfig,
        CoreFeesConfig memory coreFeesConfig,
        LPStakingConfig memory lpConfig,
        ConvexConfig memory strategyConfig
    ) LPStakingStrategy(coreAccessControlConfig, coreSwapConfig, coreFeesConfig, lpConfig) {
        cfg = strategyConfig;
    }

    function _enter(uint256[] calldata amounts, uint256 minAmount) internal override returns (uint256 stakedAmount) {
        _addLiquidity(amounts, minAmount);
        stakedAmount = DefinitiveAssets.getBalance(LP_TOKEN);
        _stake(stakedAmount);
    }

    /**
     * @notice Exit Implementation - Unstake LP tokens, and remove liquidity to one asset
     * @dev Protocol does not claim when unstaking, need to manually claim on the client side
     */
    function _exit(uint256 lpTokenAmount, uint256[] calldata minAmounts) internal override {
        _unstake(lpTokenAmount);
        _removeLiquidity(lpTokenAmount, minAmounts);
    }

    /**
     * @notice ExitOne Implementation - Unstake LP tokens, and remove liquidity to one asset
     * @dev Protocol does not claim when unstaking, need to manually claim on the client side
     */
    function _exitOne(uint256 lpTokenAmount, uint256 minAmount, uint8 index) internal override {
        _unstake(lpTokenAmount);
        _removeLiquidityOneCoin(lpTokenAmount, minAmount, index);
    }
}
