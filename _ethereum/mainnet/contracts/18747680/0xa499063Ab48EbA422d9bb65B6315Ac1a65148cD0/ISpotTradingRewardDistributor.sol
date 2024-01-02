// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "./ISpotTradingRewardDistributorStorage.sol";
import "./IPausable.sol";

interface ISpotTradingRewardDistributor is ISpotTradingRewardDistributorStorage, IPausable {
    event SpotTradingClaimReward(address indexed trader, uint256 amount);
    event RewardPerPeriodDecreased(uint256 indexed rewardPerPeriod);
    event TopUpUndistributedPmxBalance(uint256 indexed amount);
    event RewardPerPeriodChanged(uint256 indexed rewardPerPeriod);
    event PmxWithdrawn(uint256 indexed amount);

    /**
     * @dev contract initializer
     * @param registry The address of Registry contract
     * @param periodDuration The duration of a reward period
     * @param priceOracle The address of PriceOracle contract
     * @param pmx The address of PMX token
     * @param traderBalanceVault The address of TraderBalanceVault contract
     * @param treasury The address of Treasury contract
     */
    function initialize(
        address registry,
        uint256 periodDuration,
        address priceOracle,
        address pmx,
        address payable traderBalanceVault,
        address treasury
    ) external;

    /**
     * @dev Function to update spot trader activity. Only PM_ROLE can call it.
     * @param trader Address of a trader
     * @param positionAsset Address of a position asset
     * @param positionAmount Amount of a position asset
     */
    function updateTraderActivity(address trader, address positionAsset, uint256 positionAmount) external;

    /**
     * @dev Function to claim reward for spot trading activity.
     * Transfer rewards on the balance in traderBalanceVault
     * Emits SpotTradingClaimReward(address trader, uint256 amount)
     */
    function claimReward() external;

    /**
     * @dev Function to set new reward per period. Only BIG_TIMELOCK_ADMIN can call it.
     * @param rewardPerPeriod New value for reward per period
     */
    function setRewardPerPeriod(uint256 rewardPerPeriod) external;

    /**
     * @dev Function to decrease reward per period. Only EMERGENCY_ADMIN can call it.
     * @param _rewardPerPeriod New value for reward per period, must be less than the current value
     */
    function decreaseRewardPerPeriod(uint256 _rewardPerPeriod) external;

    /**
     * @dev Function to topUp the contract PMX balance
     * @param amount PMX amount to add to the contract balance
     */
    function topUpUndistributedPmxBalance(uint256 amount) external;

    /**
     * @dev Function to withdraw PMX from the contract to treasury
     * @param amount Amount of PMX to withdraw from the contract
     */
    function withdrawPmx(uint256 amount) external;

    /**
     * @dev Function to get SpotTraderActivity
     * @param periodNumber Period number
     * @param traderAddress Address of a trader
     * @return A struct with activity and hasClaimed members
     */
    function getSpotTraderActivity(uint256 periodNumber, address traderAddress) external view returns (uint256);

    /**
     * @dev Get information for the period corresponding to the given timestamp
     * @param timestamp The timestamp to get information about
     * @return totalReward Total reward for the corresponding period
     * @return totalActivity Total activity for the corresponding period
     */
    function getPeriodInfo(uint256 timestamp) external view returns (uint256, uint256);

    /**
     * @dev Function to get an array of period numbers when trader had any activity
     * @param trader Address of a trader
     * @return An array of period numbers with trader activity
     */
    function getPeriodsWithTraderActivity(address trader) external view returns (uint256[] memory);

    /**
     * @dev Function to calculate trader's reward for her activities during periods
     * @param trader Address of a trader
     * @return reward Amount of reward
     * @return currentPeriod The current period
     */
    function calculateReward(address trader) external view returns (uint256 reward, uint256 currentPeriod);
}
