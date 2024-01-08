//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ILPStakingRewards.sol";
import "./IRhoTokenRewards.sol";

/**
 * @title Flurry Staking Rewards Interface
 * @notice Interface for Flurry token staking functions
 *
 */
interface IFlurryStakingRewards {
    /**
     * @return amount of FLURRY rewards available for the three reward schemes
     * (Flurry Staking, LP Token Staking and rhoToken Holding)
     */
    function totalRewardsPool() external view returns (uint256);

    /**
     * @return aggregated FLURRY stakes from all stakers (in wei)
     */
    function totalStakes() external view returns (uint256);

    /**
     * @notice Retrieve the stake balance for a stakeholder.
     * @param user Stakeholder address
     * @return user staked amount (in wei)
     */
    function stakeOf(address user) external view returns (uint256);

    /**
     * @notice A method to allow a stakeholder to check his rewards.
     * @param user The stakeholder to check rewards for.
     * @return Accumulated rewards of addr holder (in wei)
     */
    function rewardOf(address user) external view returns (uint256);

    /**
     * @notice A method to allow a stakeholder to check all his rewards.
     * Includes Staking Rewards + RhoToken Rewards + LP Token Rewards
     * @param user The stakeholder to check rewards for.
     * @return Accumulated rewards of addr holder (in wei)
     */
    function totalRewardsOf(address user) external view returns (uint256);

    /**
     * @return amount of FLURRY distrubuted to all FLURRY stakers per block
     */
    function rewardsRate() external view returns (uint256);

    /**
     * @notice Total accumulated reward per token
     * @return Reward entitlement per FLURRY token staked (in wei)
     */
    function rewardsPerToken() external view returns (uint256);

    /**
     * @notice current reward rate per FLURRY token staked
     * @return rewards rate in FLURRY per block per FLURRY staked scaled by 18 decimals
     */
    function rewardRatePerTokenStaked() external view returns (uint256);

    /**
     * @notice A method to add a stake.
     * @param amount amount of flurry tokens to be staked (in wei)
     */
    function stake(uint256 amount) external;

    /**
     * @notice A method to unstake.
     * @param amount amount to unstake (in wei)
     */
    function withdraw(uint256 amount) external;

    /**
     * @notice A method to allow a stakeholder to withdraw his FLURRY staking rewards.
     */
    function claimReward() external;

    /**
     * @notice A method to allow a stakeholder to claim all his rewards.
     */
    function claimAllRewards() external;

    /**
     * @notice NOT for external use
     * @dev only callable by LPStakingRewards or RhoTokenRewards for FLURRY distribution
     * @param addr address of LP Token staker / rhoToken holder
     * @param amount amount of FLURRY token rewards to grant (in wei)
     * @return outstanding amount if claim is not successful, 0 if successful
     */
    function grantFlurry(address addr, uint256 amount) external returns (uint256);

    /**
     * @notice A method to allow a stakeholder to withdraw full stake.
     * Rewards are not automatically claimed. Use claimReward()
     */
    function exit() external;

    /**
     * @notice Admin function - set rewards rate earned for FLURRY staking per block
     * @param newRewardsRate amount of FLURRY (in wei) per block
     */
    function setRewardsRate(uint256 newRewardsRate) external;

    /**
     * @notice Admin function - A method to start rewards distribution
     * @param rewardsDuration rewards duration in number of blocks
     */
    function startRewards(uint256 rewardsDuration) external;

    /**
     * @notice Admin function - End Rewards distribution earlier, if there is one running
     */
    function endRewards() external;

    /**
     * @return true if reward is locked, false otherwise
     */
    function isLocked() external view returns (bool);

    /**
     * @notice Admin function - lock all rewards for all users for a given duration
     * This function should be called BEFORE startRewards()
     * @param lockDuration lock duration in number of blocks
     */
    function setTimeLock(uint256 lockDuration) external;

    /**
     * @notice Admin function - unlock all rewards immediately, if there is a time lock
     */
    function earlyUnlock() external;

    /**
     * @notice Admin function - withdraw other ERC20 tokens sent to this contract
     * @param token ERC20 token address to be sweeped
     * @param to address for sending sweeped tokens to
     */
    function sweepERC20Token(address token, address to) external;

    /**
     * @notice Admin function - set RhoTokenReward contract reference
     */
    function setRhoTokenRewardContract(address rhoTokenRewardAddr) external;

    /**
     * @notice Admin function - set LP Rewards contract reference
     */
    function setLPRewardsContract(address lpRewardsAddr) external;

    /**
     * @return reference to LP Staking Rewards contract
     */
    function lpStakingRewards() external returns (ILPStakingRewards);

    /**
     * @return reference to RhoToken Rewards contract
     */
    function rhoTokenRewards() external returns (IRhoTokenRewards);
}
