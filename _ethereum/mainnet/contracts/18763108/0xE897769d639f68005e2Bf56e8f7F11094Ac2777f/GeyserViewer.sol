// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.21;

import "./IERC20.sol";
import "./IGeyser.sol";
import "./IGeyserViewer.sol";

contract GeyserViewer is IGeyserViewer {
    /**
     * @inheritdoc IGeyserViewer
     */
    function getData(address geyser)
        external
        view
        returns (
            IGeyser.GeyserData memory geyserData,
            address[] memory bonusTokens,
            uint256 rewardAmount,
            uint256[] memory bonusAmounts
        )
    {
        IGeyser _geyser = IGeyser(geyser);
        geyserData = _geyser.getGeyserData();
        address rewardToken = geyserData.rewardToken;
        rewardAmount = IERC20(rewardToken).balanceOf(geyserData.rewardPool);
        uint256 bonusTokenCount = _geyser.getBonusTokenSetLength();
        bonusTokens = new address[](bonusTokenCount);
        bonusAmounts = new uint256[](bonusTokenCount);
        for (uint256 i = 0; i < bonusTokenCount; i++) {
            address bonusToken = _geyser.getBonusTokenAtIndex(i);
            bonusTokens[i] = bonusToken;
            bonusAmounts[i] = IERC20(bonusToken).balanceOf(geyserData.rewardPool);
        }
    }

    /**
     * @inheritdoc IGeyserViewer
     */
    function previewUnstakeAndClaim(address geyser, address vault, uint256 amount)
        external
        view
        returns (uint256 rewardShareNumerator, uint256 rewardShareDenominator)
    {
        IGeyser _geyser = IGeyser(geyser);
        IGeyser.GeyserData memory geyserData = _geyser.getGeyserData();

        // fetch vault storage reference
        IGeyser.VaultData memory vaultData = _geyser.getVaultData(vault);

        if (vaultData.totalStake < amount) {
            // Would normally be fatal but easier to just gloss over it than handle errors clientside
            amount = vaultData.totalStake;
        }

        if (amount == 0) {
            // Return early with a reward share of zero
            rewardShareNumerator = 0;
            rewardShareDenominator = 1;
            return (rewardShareNumerator, rewardShareDenominator);
        }

        if (geyserData.totalStake < amount) {
            // If this check fails, there is a bug in stake accounting
            // Do nothing however as it's a problem best handled elsewhere
        }

        // update cached totalStakeUnits
        geyserData.totalStakeUnits = _geyser.getCurrentTotalStakeUnits();

        // get reward amount remaining
        uint256 remainingRewards = IERC20(geyserData.rewardToken).balanceOf(geyserData.rewardPool);

        // calculate vested portion of reward pool
        uint256 unlockedRewards = _geyser.calculateUnlockedRewards(
            geyserData.rewardSchedules, remainingRewards, geyserData.rewardSharesOutstanding, block.timestamp
        );

        // calculate vault time weighted reward with scaling
        IGeyser.RewardOutput memory out = _geyser.calculateRewardFromStakes(
            vaultData.stakes,
            amount,
            unlockedRewards,
            geyserData.totalStakeUnits,
            block.timestamp,
            geyserData.rewardScaling
        );

        rewardShareNumerator = out.reward;
        rewardShareDenominator = unlockedRewards;
    }
}
