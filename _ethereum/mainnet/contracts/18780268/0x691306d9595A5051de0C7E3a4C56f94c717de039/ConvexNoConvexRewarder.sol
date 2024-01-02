// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./DefinitiveAssets.sol";
import "./ConvexBase.sol";
import "./DefinitiveErrors.sol";

import "./LPStakingStrategy.sol";
import "./Interfaces.sol";

/// @title ConvexNoConvexRewarder
/// @author Definitive
/// @dev implementing strategies MUST set rewardTokensStorage in the constructor
/// @notice LP_STAKING also has all rewards related logic
abstract contract ConvexNoConvexRewarder is ConvexBase {
    using DefinitiveAssets for IERC20;

    IERC20[] internal rewardTokensStorage;

    constructor(
        CoreAccessControlConfig memory coreAccessControlConfig,
        CoreSwapConfig memory coreSwapConfig,
        CoreFeesConfig memory coreFeesConfig,
        LPStakingConfig memory lpConfig,
        ConvexConfig memory strategyConfig
    ) ConvexBase(coreAccessControlConfig, coreSwapConfig, coreFeesConfig, lpConfig, strategyConfig) {}

    // Stakes Curve LP tokens into Convex
    function _stake(uint256 amount) internal override {
        address mLP_TOKEN = LP_TOKEN;
        address mLP_STAKING = LP_STAKING;

        DefinitiveAssets.validateBalance(mLP_TOKEN, amount);
        IERC20(mLP_TOKEN).resetAndSafeIncreaseAllowance(address(this), mLP_STAKING, amount);

        bool success = IConvexDepositToken(mLP_STAKING).deposit(address(this), amount);
        if (!success) {
            revert StakeFailed();
        }
    }

    /**
     * @dev Setting withdrawAndUnwrap to false does not claim reward tokens
     */
    function _unstake(uint256 amount) internal override {
        if (_getAmountStaked() < amount) {
            revert InputGreaterThanStaked();
        }

        bool success = IConvexDepositToken(LP_STAKING).withdraw(address(this), amount);
        if (!success) {
            revert UnstakeFailed();
        }
    }

    function _getAmountStaked() internal view override returns (uint256) {
        return IConvexDepositToken(LP_STAKING).balanceOf(address(this));
    }

    function _claimAllRewards()
        internal
        override
        returns (IERC20[] memory rewardTokens, uint256[] memory earnedAmounts)
    {
        rewardTokens = rewardTokensStorage;
        uint256 rewardTokensLength = rewardTokens.length;

        earnedAmounts = new uint256[](rewardTokensLength);

        if (rewardTokensLength == 3) {
            (earnedAmounts[0], earnedAmounts[1], earnedAmounts[2]) = IConvexDepositToken(LP_STAKING).claimReward(
                address(this)
            );
        } else {
            revert InvalidRewardsClaim();
        }
    }

    function unclaimedRewards()
        public
        view
        override
        returns (IERC20[] memory rewardTokens, uint256[] memory earnedAmounts)
    {
        rewardTokens = rewardTokensStorage;
        uint256 rewardTokensLength = rewardTokens.length;

        earnedAmounts = new uint256[](rewardTokensLength);

        if (rewardTokensLength == 3) {
            (earnedAmounts[0], earnedAmounts[1], earnedAmounts[2]) = IConvexDepositToken(LP_STAKING).claimableReward(
                address(this)
            );
        } else {
            revert InvalidRewardsClaim();
        }
    }
}
