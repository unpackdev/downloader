// SPDX-License-Identifier: GPL-2.0-or-later
// (C) Florence Finance, 2022 - https://florence.finance/
pragma solidity 0.8.9;

import "./Math.sol";
import "./Util.sol";
import "./console.sol";

/// @title Linear staking contract
/// @dev this library contains all funcionality related to the linear staking mechanism
/// Curve Token owner stake their curve token and receive Medici (MDC) token as rewards.
/// The amount of reward token (MDC) is calculated based on:
/// - the number of staked curve token
/// - the number of blocks the curve tokens are beig staked
/// - the amount of MDC rewards per Block per staked curve token
/// E.g. 10 MDC reward token per block per staked curve token
/// staker 1 stakes 100 curve token and claims rewards (MDC) after 200 Blocks
/// staker 1 recieves 200000 MDC reward tokens (200 blocks * 10 MDC/Block/CurveToken * 100 CurveToken)

library LinearStaking {
    event RewardTokensPerBlockUpdated(IERC20 stakedToken, IERC20 rewardToken, uint256 oldRewardTokensPerBlock, uint256 newRewardTokensPerBlock);
    event RewardsLockedUpdated(IERC20 stakedToken, IERC20 rewardToken, bool rewardsLocked);
    event StakedLinear(address indexed staker, IERC20 indexed stakableToken, uint256 amount);
    event UnstakedLinear(address indexed unstaker, IERC20 indexed stakedToken, uint256 amount, uint256 totalStakedBalance);
    event ClaimedRewardsLinear(address indexed claimer, IERC20 stakedToken, IERC20 rewardToken, uint256 amount);
    event RewardsDeposited(address depositor, IERC20 rewardToken, uint256 amount);

    struct LinearStakingStorage {
        IERC20[] stakableTokens;
        /// @dev configuration of rewards for particular stakable tokens
        mapping(IERC20 => RewardConfiguration) rewardConfigurations;
        /// @dev storage of accumulated staking rewards for the pool participants addresses
        mapping(address => mapping(IERC20 => WalletStakingState)) walletStakingStates;
        /// @dev amount of tokens available to be distributed as staking rewards
        mapping(IERC20 => uint256) availableRewards;
    }

    struct RewardConfiguration {
        bool isStakable;
        IERC20[] rewardTokens;
        // mapping(IERC20 => uint256) rewardTokensPerBlock; //Old, should be removed when new algorithm is implemented

        // RewardToken => BlockNumber => RewardTokensPerBlock
        mapping(IERC20 => mapping(uint256 => uint256)) rewardTokensPerBlockHistory;
        // RewardToken => BlockNumbers/Keys of rewardTokensPerBlockHistory[RewardToken][BlockNumbers]
        mapping(IERC20 => uint256[]) rewardTokensPerBlockHistoryBlocks;
        mapping(IERC20 => bool) rewardsLocked;
    }

    struct WalletStakingState {
        uint256 stakedBalance;
        uint256 lastUpdate;
        mapping(IERC20 => uint256) outstandingRewards;
    }

    /// @dev Sets the rewardTokensPerBlock for a stakedToken-rewardToken pair
    /// @param linearStakingStorage pointer to linear staking storage struct
    /// @param stakedToken the staked token
    /// @param rewardToken the reward token
    /// @param rewardTokensPerBlock rewardTokens per rewardToken per block (rewardToken decimals)
    function setRewardTokensPerBlockLinear(
        LinearStakingStorage storage linearStakingStorage,
        IERC20 stakedToken,
        IERC20 rewardToken,
        uint256 rewardTokensPerBlock
    ) public {
        require(address(stakedToken) != address(0) && address(rewardToken) != address(0), "token adress cannot be zero");

        RewardConfiguration storage rewardConfiguration = linearStakingStorage.rewardConfigurations[stakedToken];

        uint256[] storage rewardTokensPerBlockHistoryBlocks = rewardConfiguration.rewardTokensPerBlockHistoryBlocks[rewardToken];

        uint256 currentRewardTokensPerBlock = 0;

        if (rewardTokensPerBlockHistoryBlocks.length > 0) {
            uint256 lastRewardTokensPerBlockBlock = rewardTokensPerBlockHistoryBlocks[rewardTokensPerBlockHistoryBlocks.length - 1];
            currentRewardTokensPerBlock = rewardConfiguration.rewardTokensPerBlockHistory[rewardToken][lastRewardTokensPerBlockBlock];
        }

        require(rewardTokensPerBlock != currentRewardTokensPerBlock, "rewardTokensPerBlock already set to expected value");

        if (rewardTokensPerBlock != 0 && currentRewardTokensPerBlock == 0) {
            rewardConfiguration.rewardTokens.push(rewardToken);
            if (rewardConfiguration.rewardTokens.length == 1) {
                linearStakingStorage.stakableTokens.push(stakedToken);
            }
        }

        if (rewardTokensPerBlock == 0 && currentRewardTokensPerBlock != 0) {
            Util.removeValueFromArray(rewardToken, rewardConfiguration.rewardTokens);
            if (rewardConfiguration.rewardTokens.length == 0) {
                Util.removeValueFromArray(stakedToken, linearStakingStorage.stakableTokens);
            }
        }

        rewardConfiguration.isStakable = rewardTokensPerBlock != 0;

        rewardConfiguration.rewardTokensPerBlockHistory[rewardToken][block.number] = rewardTokensPerBlock;
        rewardTokensPerBlockHistoryBlocks.push(block.number);

        emit RewardTokensPerBlockUpdated(stakedToken, rewardToken, currentRewardTokensPerBlock, rewardTokensPerBlock);
    }

    /// @dev Locks/Unlocks the reward token (MDC) for a certain staking token (Curve Token)
    /// @param linearStakingStorage pointer to linear staking storage struct
    /// @param stakedToken the staked token
    /// @param rewardToken the reward token
    /// @param rewardsLocked true = lock rewards; false = unlock rewards
    function setRewardsLockedLinear(
        LinearStakingStorage storage linearStakingStorage,
        IERC20 stakedToken,
        IERC20 rewardToken,
        bool rewardsLocked
    ) public {
        require(address(stakedToken) != address(0) && address(rewardToken) != address(0), "token adress cannot be zero");

        if (linearStakingStorage.rewardConfigurations[stakedToken].rewardsLocked[rewardToken] != rewardsLocked) {
            linearStakingStorage.rewardConfigurations[stakedToken].rewardsLocked[rewardToken] = rewardsLocked;
            emit RewardsLockedUpdated(stakedToken, rewardToken, rewardsLocked);
        }
    }

    /// @dev Staking of a stakable token
    /// @param linearStakingStorage pointer to linear staking storage struct
    /// @param stakableToken the stakeable token
    /// @param amount the amount to stake (stakableToken decimals)
    function stakeLinear(
        LinearStakingStorage storage linearStakingStorage,
        IERC20 stakableToken,
        uint256 amount
    ) public {
        require(amount > 0, "amount must be greater zero");
        require(linearStakingStorage.rewardConfigurations[stakableToken].isStakable, "token is not stakable");
        updateRewardSnapshotLinear(linearStakingStorage, msg.sender, stakableToken);
        linearStakingStorage.walletStakingStates[msg.sender][stakableToken].stakedBalance += Util.checkedTransferFrom(stakableToken, msg.sender, address(this), amount);
        emit StakedLinear(msg.sender, stakableToken, amount);
    }

    /// @dev Unstaking of a staked token
    /// @param linearStakingStorage pointer to linear staking storage struct
    /// @param stakedToken the staked token
    /// @param amount the amount to unstake
    function unstakeLinear(
        LinearStakingStorage storage linearStakingStorage,
        IERC20 stakedToken,
        uint256 amount
    ) public {
        amount = Math.min(amount, linearStakingStorage.walletStakingStates[msg.sender][stakedToken].stakedBalance);
        require(amount > 0, "amount must be greater zero");
        updateRewardSnapshotLinear(linearStakingStorage, msg.sender, stakedToken);
        linearStakingStorage.walletStakingStates[msg.sender][stakedToken].stakedBalance -= amount;
        stakedToken.transfer(msg.sender, amount);
        uint256 totalStakedBalance = linearStakingStorage.walletStakingStates[msg.sender][stakedToken].stakedBalance;
        emit UnstakedLinear(msg.sender, stakedToken, amount, totalStakedBalance);
        // emit UnstakedLinear(msg.sender, stakedToken, amount);
    }

    /// @dev Updates the outstanding rewards for a specific wallet and staked token. This needs to be called every time before any changes to staked balances are made
    /// @param linearStakingStorage pointer to linear staking storage struct
    /// @param wallet the wallet
    /// @param stakedToken the staked token
    function updateRewardSnapshotLinear(
        LinearStakingStorage storage linearStakingStorage,
        address wallet,
        IERC20 stakedToken
    ) internal {
        uint256 lastUpdate = linearStakingStorage.walletStakingStates[wallet][stakedToken].lastUpdate;

        if (lastUpdate != 0) {
            IERC20[] memory rewardTokens = linearStakingStorage.rewardConfigurations[stakedToken].rewardTokens;
            for (uint256 i = 0; i < rewardTokens.length; i++) {
                IERC20 rewardToken = rewardTokens[i];
                uint256 newOutstandingRewards = calculateRewardsLinear(linearStakingStorage, wallet, stakedToken, rewardToken);
                linearStakingStorage.walletStakingStates[wallet][stakedToken].outstandingRewards[rewardToken] = newOutstandingRewards;
            }
        }
        linearStakingStorage.walletStakingStates[wallet][stakedToken].lastUpdate = block.number;
    }

    /// @dev Calculates the outstanding rewards for a wallet, staked token and reward token
    /// @param linearStakingStorage pointer to linear staking storage struct
    /// @param wallet the wallet
    /// @param stakedToken the staked token
    /// @param rewardToken the reward token
    /// @return the outstading rewards (rewardToken decimals)
    function calculateRewardsLinear(
        LinearStakingStorage storage linearStakingStorage,
        address wallet,
        IERC20 stakedToken,
        IERC20 rewardToken
    ) public view returns (uint256) {
        uint256 lastUpdate = linearStakingStorage.walletStakingStates[wallet][stakedToken].lastUpdate;

        if (lastUpdate != 0) {
            uint256 stakedBalance = linearStakingStorage.walletStakingStates[wallet][stakedToken].stakedBalance / 10**Util.getERC20Decimals(stakedToken);

            uint256 accumulatedRewards; // = 0
            uint256 rewardRangeStart;
            uint256 rewardRangeStop = block.number;
            uint256 rewardRangeTokensPerBlock;
            uint256 rewardRangeBlocks;

            uint256[] memory fullHistory = linearStakingStorage.rewardConfigurations[stakedToken].rewardTokensPerBlockHistoryBlocks[rewardToken];
            uint256 i = fullHistory.length - 1;
            for (; i >= 0; i--) {
                rewardRangeStart = fullHistory[i]; // Block numbers at which the rewards per Block changed in history
                rewardRangeTokensPerBlock = linearStakingStorage.rewardConfigurations[stakedToken].rewardTokensPerBlockHistory[rewardToken][fullHistory[i]];

                if (rewardRangeStart < lastUpdate) {
                    rewardRangeStart = lastUpdate;
                }

                rewardRangeBlocks = rewardRangeStop - rewardRangeStart;

                accumulatedRewards += stakedBalance * rewardRangeBlocks * rewardRangeTokensPerBlock;

                if (rewardRangeStart == lastUpdate) break;

                rewardRangeStop = rewardRangeStart;
            }

            uint256 outStandingRewards = linearStakingStorage.walletStakingStates[wallet][stakedToken].outstandingRewards[rewardToken];

            return (outStandingRewards + accumulatedRewards);
        }
        return 0;
    }

    /// @dev Claims all rewards for a staked tokens
    /// @param linearStakingStorage pointer to linear staking storage struct
    /// @param stakedToken the staked token
    function claimRewardsLinear(LinearStakingStorage storage linearStakingStorage, IERC20 stakedToken) public {
        updateRewardSnapshotLinear(linearStakingStorage, msg.sender, stakedToken);

        IERC20[] memory rewardTokens = linearStakingStorage.rewardConfigurations[stakedToken].rewardTokens;
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            IERC20 rewardToken = rewardTokens[i];

            if (linearStakingStorage.rewardConfigurations[stakedToken].rewardsLocked[rewardToken]) {
                //rewards for the token are not claimable yet
                continue;
            }

            uint256 rewardAmount = linearStakingStorage.walletStakingStates[msg.sender][stakedToken].outstandingRewards[rewardToken];
            uint256 payableRewardAmount = Math.min(rewardAmount, linearStakingStorage.availableRewards[rewardToken]);
            require(payableRewardAmount > 0, "no rewards available for payout");

            linearStakingStorage.walletStakingStates[msg.sender][stakedToken].outstandingRewards[rewardToken] -= payableRewardAmount;
            linearStakingStorage.availableRewards[rewardToken] -= payableRewardAmount;

            rewardToken.transfer(msg.sender, payableRewardAmount);
            emit ClaimedRewardsLinear(msg.sender, stakedToken, rewardToken, payableRewardAmount);
        }
    }

    /// @dev Allows the deposit of reward funds. This is usually used by the borrower or treasury
    /// @param linearStakingStorage pointer to linear staking storage struct
    /// @param rewardToken the reward token
    /// @param amount the amount of tokens (rewardToken decimals)
    function depositRewardsLinear(
        LinearStakingStorage storage linearStakingStorage,
        IERC20 rewardToken,
        uint256 amount
    ) public {
        linearStakingStorage.availableRewards[rewardToken] += Util.checkedTransferFrom(rewardToken, msg.sender, address(this), amount);
        emit RewardsDeposited(msg.sender, rewardToken, amount);
    }

    /// @dev Get the staked balance for a specific token and wallet
    /// @param linearStakingStorage pointer to linear staking storage struct
    /// @param wallet the wallet
    /// @param stakableToken the staked token
    /// @return the staked balance (stakableToken decimals)
    function getStakedBalanceLinear(
        LinearStakingStorage storage linearStakingStorage,
        address wallet,
        IERC20 stakableToken
    ) public view returns (uint256) {
        return linearStakingStorage.walletStakingStates[wallet][stakableToken].stakedBalance;
    }
}
