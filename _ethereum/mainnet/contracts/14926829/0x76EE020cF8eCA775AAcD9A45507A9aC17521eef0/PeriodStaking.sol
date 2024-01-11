// SPDX-License-Identifier: GPL-2.0-or-later
// (C) Florence Finance, 2022 - https://florence.finance/
pragma solidity 0.8.9;

import "./Util.sol";
import "./Math.sol";
import "./console.sol";

/// @title Period staking contract
/// @dev this library contains all funcionality related to the period staking mechanism
/// Lending Pool Token (LPT) owner stake their LPTs within an active staking period (e.g. staking period could be three months)
/// The LPTs can remain staked over several consecutive periods while accumulating staking rewards (currently USDC token).
/// The amount of staking rewards depends on the total staking score per staking period of the LPT owner address and
/// on the total amount of rewards distrubuted for this staking period
/// E.g. Staking period is 90 days and total staking rewards is 900 USDC
/// LPT staker 1 stakes 100 LPTs during the whole 90 days
/// LPT staker 2 starts staking after 45 days and stakes 100 LPTs until the end of the staking period
/// staker 1 staking score is 600 and staker 2 staking score is 300
/// staker 1 claims 600 USDC after staking period is completed
/// staker 2 claims 300 USDC after staking period is completed
/// the staking rewards need to be claimed actively after each staking period is completed and the total rewards have been deposited to the contract by the Borrower

library PeriodStaking {
    event StakedPeriod(address indexed staker, IERC20 indexed stakableToken, uint256 amount);
    event UnstakedPeriod(address indexed unstaker, IERC20 indexed stakedToken, uint256 amount, uint256 totalStakedBalance);
    event ClaimedRewardsPeriod(address indexed claimer, IERC20 stakedToken, IERC20 rewardToken, uint256 amount);
    event ChangedEndRewardPeriod(uint256 indexed _periodId, uint256 _periodStart, uint256 _periodEnd);

    struct PeriodStakingStorage {
        mapping(uint256 => RewardPeriod) rewardPeriods;
        mapping(address => WalletStakingState) walletStakedAmounts;
        mapping(uint256 => mapping(address => uint256)) walletStakingScores;
        uint256 currentRewardPeriodId;
        uint256 duration;
        IERC20 rewardToken;
        mapping(uint256 => mapping(address => uint256)) walletRewardableCapital;
    }

    struct RewardPeriod {
        uint256 id;
        uint256 start;
        uint256 end;
        uint256 totalRewards;
        uint256 totalStakingScore;
        uint256 finalStakedAmount;
        IERC20 rewardToken;
    }

    struct WalletStakingState {
        uint256 stakedBalance;
        uint256 lastUpdate;
        mapping(IERC20 => uint256) outstandingRewards;
    }

    /// @dev Get the struct/info of all reward periods
    /// @param periodStakingStorage pointer to period staking storage struct
    /// @return returns the array including all reward period structs
    function getRewardPeriods(PeriodStakingStorage storage periodStakingStorage) external view returns (RewardPeriod[] memory) {
        RewardPeriod[] memory rewardPeriodsArray = new RewardPeriod[](periodStakingStorage.currentRewardPeriodId);

        for (uint256 i = 1; i <= periodStakingStorage.currentRewardPeriodId; i++) {
            RewardPeriod storage rewardPeriod = periodStakingStorage.rewardPeriods[i];
            rewardPeriodsArray[i - 1] = rewardPeriod;
        }
        return rewardPeriodsArray;
    }

    /// @dev End the current reward period
    /// @param periodEnd block number of new end of the current reward period
    /// periodEnd == 0 sets current reward period end to current block number
    function setEndRewardPeriod(PeriodStakingStorage storage periodStakingStorage, uint256 periodEnd) external {
        RewardPeriod storage currentRewardPeriod = periodStakingStorage.rewardPeriods[periodStakingStorage.currentRewardPeriodId];
        require(currentRewardPeriod.id > 0, "no reward periods");
        require(currentRewardPeriod.start < block.number && currentRewardPeriod.end > block.number, "not inside any reward period");

        if (periodEnd == 0) {
            currentRewardPeriod.end = block.number;
        } else {
            require(periodEnd >= block.number, "end of period in the past");
            currentRewardPeriod.end = periodEnd;
        }
        emit ChangedEndRewardPeriod(currentRewardPeriod.id, currentRewardPeriod.start, currentRewardPeriod.end);
    }

    /// @dev Start the next reward period
    /// @param periodStakingStorage pointer to period staking storage struct
    /// @param periodStart start block of the period, 0 == follow previous period, 1 == start at current block, >1 use passed value
    function startNextRewardPeriod(PeriodStakingStorage storage periodStakingStorage, uint256 periodStart) external {
        require(periodStakingStorage.duration > 0 && address(periodStakingStorage.rewardToken) != address(0), "duration and/or rewardToken not configured");

        RewardPeriod storage currentRewardPeriod = periodStakingStorage.rewardPeriods[periodStakingStorage.currentRewardPeriodId];
        if (periodStakingStorage.currentRewardPeriodId > 0) {
            require(currentRewardPeriod.end > 0 && currentRewardPeriod.end < block.number, "current period has not ended yet");
        }
        periodStakingStorage.currentRewardPeriodId += 1;
        RewardPeriod storage nextRewardPeriod = periodStakingStorage.rewardPeriods[periodStakingStorage.currentRewardPeriodId];
        nextRewardPeriod.rewardToken = periodStakingStorage.rewardToken;

        nextRewardPeriod.id = periodStakingStorage.currentRewardPeriodId;

        if (periodStart == 0) {
            nextRewardPeriod.start = currentRewardPeriod.end != 0 ? currentRewardPeriod.end : block.number;
        } else if (periodStart == 1) {
            nextRewardPeriod.start = block.number;
        } else {
            nextRewardPeriod.start = periodStart;
        }

        nextRewardPeriod.end = nextRewardPeriod.start + periodStakingStorage.duration;
        nextRewardPeriod.finalStakedAmount = currentRewardPeriod.finalStakedAmount;
        nextRewardPeriod.totalStakingScore = currentRewardPeriod.finalStakedAmount * (nextRewardPeriod.end - nextRewardPeriod.start);
    }

    /// @dev Deposit the rewards (USDC token) for a reward period
    /// @param periodStakingStorage pointer to period staking storage struct
    /// @param rewardPeriodId The ID of the reward period
    /// @param _totalRewards total amount of period rewards to deposit
    function depositRewardPeriodRewards(
        PeriodStakingStorage storage periodStakingStorage,
        uint256 rewardPeriodId,
        uint256 _totalRewards
    ) public {
        RewardPeriod storage rewardPeriod = periodStakingStorage.rewardPeriods[rewardPeriodId];

        require(rewardPeriod.end > 0 && rewardPeriod.end < block.number, "period has not ended");

        periodStakingStorage.rewardPeriods[rewardPeriodId].totalRewards = Util.checkedTransferFrom(rewardPeriod.rewardToken, msg.sender, address(this), _totalRewards);
    }

    /// @dev Updates the staking score for a wallet over all staking periods
    /// @param periodStakingStorage pointer to period staking storage struct
    function updatePeriod(PeriodStakingStorage storage periodStakingStorage) internal {
        WalletStakingState storage walletStakedAmount = periodStakingStorage.walletStakedAmounts[msg.sender];
        if (walletStakedAmount.stakedBalance > 0 && walletStakedAmount.lastUpdate < periodStakingStorage.currentRewardPeriodId && walletStakedAmount.lastUpdate > 0) {
            uint256 i = walletStakedAmount.lastUpdate + 1;
            for (; i <= periodStakingStorage.currentRewardPeriodId; i++) {
                RewardPeriod storage rewardPeriod = periodStakingStorage.rewardPeriods[i];
                periodStakingStorage.walletStakingScores[i][msg.sender] = walletStakedAmount.stakedBalance * (rewardPeriod.end - rewardPeriod.start);
                periodStakingStorage.walletRewardableCapital[i][msg.sender] = calculateRewardableCapital(rewardPeriod, walletStakedAmount.stakedBalance);
            }
        }
        walletStakedAmount.lastUpdate = periodStakingStorage.currentRewardPeriodId;
    }

    /// @dev Calculate the staking score for a wallet for a given rewards period
    /// @param periodStakingStorage pointer to period staking storage struct
    /// @param wallet wallet address
    /// @param period period ID for which to calculate the staking rewards
    /// @return wallet staking score for a given rewards period
    function getWalletRewardPeriodStakingScore(
        PeriodStakingStorage storage periodStakingStorage,
        address wallet,
        uint256 period
    ) public view returns (uint256) {
        WalletStakingState storage walletStakedAmount = periodStakingStorage.walletStakedAmounts[wallet];
        RewardPeriod storage rewardPeriod = periodStakingStorage.rewardPeriods[period];
        if (walletStakedAmount.lastUpdate > 0 && walletStakedAmount.lastUpdate < period) {
            return walletStakedAmount.stakedBalance * (rewardPeriod.end - rewardPeriod.start);
        } else {
            return periodStakingStorage.walletStakingScores[period][wallet];
        }
    }

    /// @dev Stake Lending Pool Token in current rewards period
    /// @notice emits event StakedPeriod
    /// @param periodStakingStorage pointer to period staking storage struct
    /// @param amount amount of LPT to stake
    /// @param lendingPoolToken Lending Pool Token address
    function stakeRewardPeriod(
        PeriodStakingStorage storage periodStakingStorage,
        uint256 amount,
        IERC20 lendingPoolToken
    ) external {
        RewardPeriod storage currentRewardPeriod = periodStakingStorage.rewardPeriods[periodStakingStorage.currentRewardPeriodId];
        require(currentRewardPeriod.start <= block.number && currentRewardPeriod.end > block.number, "no active period");

        updatePeriod(periodStakingStorage);

        amount = Util.checkedTransferFrom(lendingPoolToken, msg.sender, address(this), amount);
        emit StakedPeriod(msg.sender, lendingPoolToken, amount);

        periodStakingStorage.walletStakedAmounts[msg.sender].stakedBalance += amount;

        currentRewardPeriod.finalStakedAmount += amount;

        currentRewardPeriod.totalStakingScore += (currentRewardPeriod.end - block.number) * amount;

        periodStakingStorage.walletStakingScores[periodStakingStorage.currentRewardPeriodId][msg.sender] += (currentRewardPeriod.end - block.number) * amount;

        periodStakingStorage.walletRewardableCapital[periodStakingStorage.currentRewardPeriodId][msg.sender] += calculateRewardableCapital(currentRewardPeriod, amount);
    }

    /// @dev Unstake Lending Pool Token
    /// @notice emits event UnstakedPeriod
    /// @param periodStakingStorage pointer to period staking storage struct
    /// @param amount amount of LPT to unstake
    /// @param lendingPoolToken Lending Pool Token address
    function unstakeRewardPeriod(
        PeriodStakingStorage storage periodStakingStorage,
        uint256 amount,
        IERC20 lendingPoolToken
    ) external {
        require(amount <= periodStakingStorage.walletStakedAmounts[msg.sender].stakedBalance, "amount greater than staked amount");
        updatePeriod(periodStakingStorage);

        RewardPeriod storage currentRewardPeriod = periodStakingStorage.rewardPeriods[periodStakingStorage.currentRewardPeriodId];

        periodStakingStorage.walletStakedAmounts[msg.sender].stakedBalance -= amount;
        currentRewardPeriod.finalStakedAmount -= amount;
        if (currentRewardPeriod.end > block.number) {
            currentRewardPeriod.totalStakingScore -= (currentRewardPeriod.end - block.number) * amount;
            periodStakingStorage.walletStakingScores[periodStakingStorage.currentRewardPeriodId][msg.sender] -= (currentRewardPeriod.end - block.number) * amount;
            uint256 value = calculateRewardableCapital(currentRewardPeriod, amount);
            periodStakingStorage.walletRewardableCapital[periodStakingStorage.currentRewardPeriodId][msg.sender] -= value;
        }
        lendingPoolToken.transfer(msg.sender, amount);
        emit UnstakedPeriod(msg.sender, lendingPoolToken, amount, periodStakingStorage.walletStakedAmounts[msg.sender].stakedBalance);
    }

    /// @dev Claim rewards (USDC) for a certain staking period
    /// @notice emits event ClaimedRewardsPeriod
    /// @param periodStakingStorage pointer to period staking storage struct
    /// @param rewardPeriodId period ID of which to claim staking rewards
    /// @param lendingPoolToken Lending Pool Token address
    function claimRewardPeriod(
        PeriodStakingStorage storage periodStakingStorage,
        uint256 rewardPeriodId,
        IERC20 lendingPoolToken
    ) external {
        RewardPeriod storage rewardPeriod = periodStakingStorage.rewardPeriods[rewardPeriodId];
        require(rewardPeriod.end > 0 && rewardPeriod.end < block.number && rewardPeriod.totalRewards > 0, "period not ready for claiming");
        updatePeriod(periodStakingStorage);

        require(periodStakingStorage.walletStakingScores[rewardPeriodId][msg.sender] > 0, "no rewards to claim");

        uint256 payableRewardAmount = calculatePeriodRewards(
            rewardPeriod.rewardToken,
            rewardPeriod.totalRewards,
            rewardPeriod.totalStakingScore,
            periodStakingStorage.walletStakingScores[rewardPeriodId][msg.sender]
        );
        periodStakingStorage.walletStakingScores[rewardPeriodId][msg.sender] = 0;

        // This condition can never be true, because:
        // calculateRewardsPeriod can never have a walletStakingScore > totalPeriodStakingScore
        // require(payableRewardAmount > 0, "no rewards to claim");

        rewardPeriod.rewardToken.transfer(msg.sender, payableRewardAmount);
        emit ClaimedRewardsPeriod(msg.sender, lendingPoolToken, rewardPeriod.rewardToken, payableRewardAmount);
    }

    /// @dev Calculate the staking rewards of a staking period for a wallet address
    /// @param periodStakingStorage pointer to period staking storage struct
    /// @param rewardPeriodId period ID for which to calculate the rewards
    /// @param projectedTotalRewards The amount of total rewards which is planned to be deposited at the end of the staking period
    /// @return returns the amount of staking rewards for a wallet address for a certain staking period
    function calculateWalletRewardsPeriod(
        PeriodStakingStorage storage periodStakingStorage,
        address wallet,
        uint256 rewardPeriodId,
        uint256 projectedTotalRewards
    ) public view returns (uint256) {
        RewardPeriod storage rewardPeriod = periodStakingStorage.rewardPeriods[rewardPeriodId];
        if (projectedTotalRewards == 0) {
            projectedTotalRewards = rewardPeriod.totalRewards;
        }
        return
            calculatePeriodRewards(
                rewardPeriod.rewardToken,
                projectedTotalRewards,
                rewardPeriod.totalStakingScore,
                getWalletRewardPeriodStakingScore(periodStakingStorage, wallet, rewardPeriodId)
            );
    }

    function calculateWalletRewardsYieldPeriod(
        PeriodStakingStorage storage periodStakingStorage,
        address wallet,
        uint256 rewardPeriodId,
        uint256 yieldPeriod,
        IERC20 lendingPoolToken
    ) public view returns (uint256) {
        RewardPeriod storage rewardPeriod = periodStakingStorage.rewardPeriods[rewardPeriodId];
        if (rewardPeriod.totalRewards != 0) {
            return calculateWalletRewardsPeriod(periodStakingStorage, wallet, rewardPeriodId, rewardPeriod.totalRewards);
        }

        uint256 walletRewardableCapital = periodStakingStorage.walletRewardableCapital[rewardPeriod.id][wallet];
        uint256 currentStakedBalance = periodStakingStorage.walletStakedAmounts[wallet].stakedBalance;

        if (currentStakedBalance != 0 && walletRewardableCapital == 0) {
            walletRewardableCapital = calculateRewardableCapital(rewardPeriod, currentStakedBalance);
        } else if (rewardPeriod.end > block.number) {
            // WalletStakingState storage walletStakedAmount = periodStakingStorage.walletStakedAmounts[wallet];

            // if(walletStakedAmount.lastUpdate == rewardPeriod.id) {
            //     // IF UPDATE has been done within this period.id
            // console.log("test walletRewardableCapital", walletRewardableCapital);
            //     walletRewardableCapital = calculateRewardableCapital(rewardPeriod, currentStakedBalance);
            // }
            // else {
            walletRewardableCapital -= calculateRewardableCapital(rewardPeriod, currentStakedBalance);
            // }
        }

        uint256 walletRewards18 = (walletRewardableCapital * yieldPeriod) / 10000 / 100;
        return Util.convertDecimalsERC20(walletRewards18, lendingPoolToken, rewardPeriod.rewardToken);
    }

    /// @dev Calculate the total amount of payable rewards
    /// @param rewardToken The reward token (e.g. USDC)
    /// @param totalPeriodRewards The total amount of rewards for a certain period
    /// @param totalPeriodStakingScore The total staking score (of all wallet addresses during a certain staking period)
    /// @param walletStakingScore The total staking score (of one wallet address during a certain staking period)
    /// @return returns the total payable amount of staking rewards
    function calculatePeriodRewards(
        IERC20 rewardToken,
        uint256 totalPeriodRewards,
        uint256 totalPeriodStakingScore,
        uint256 walletStakingScore
    ) public view returns (uint256) {
        if (totalPeriodStakingScore == 0) {
            return 0;
        }
        uint256 rewardTokenDecimals = Util.getERC20Decimals(rewardToken);
        // uint256 payableRewardAmount = Util.percent(walletStakingScore * totalPeriodRewards, totalPeriodStakingScore, rewardTokenDecimals);
        // We need to devide after the calculation, so that the 'rest' is cut off

        uint256 _numerator = (walletStakingScore * totalPeriodRewards) * 10**(rewardTokenDecimals + 1);
        // with rounding of last digit
        uint256 payableRewardAmount = ((_numerator / totalPeriodStakingScore) + 5) / 10;

        return payableRewardAmount / (uint256(10)**rewardTokenDecimals);
    }

    function calculateRewardableCapital(RewardPeriod memory rewardPeriod, uint256 amount) internal view returns (uint256) {
        uint256 blockNumber = block.number;
        if (block.number > rewardPeriod.end) {
            blockNumber = rewardPeriod.end;
            // blockNumber = 0;
        }
        uint256 stakingDuration;

        // Ensure that in period 1 updatePeriod must have been called...
        // This is suboptimal, because period 1 could be without staking (without updatePeriod)
        // we must know whether in one of the previous periods upgrade had been called or not...

        if (rewardPeriod.id > 1) {
            //upgradePeriod has been called (rely on rewardPeriod.id is very bad...)
            // This case covers from beginning of period to 'now'
            stakingDuration = (blockNumber - rewardPeriod.start) * 10**18;
        } else {
            // This case covers from 'now' to end of period
            stakingDuration = (rewardPeriod.end - blockNumber) * 10**18;
        }
        uint256 periodDuration = (rewardPeriod.end - rewardPeriod.start);
        if (periodDuration == 0 || stakingDuration == 0 || amount == 0) {
            return 0;
        }
        return (amount * (stakingDuration / periodDuration)) / 10**18;
    }
}
