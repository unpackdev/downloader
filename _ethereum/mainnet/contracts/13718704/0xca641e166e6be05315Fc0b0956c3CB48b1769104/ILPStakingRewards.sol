//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IFlurryStakingRewards.sol";

/**
 * @title LP Staking Rewards Interface
 * @notice Interface for FLURRY token rewards when staking LP tokens
 */
interface ILPStakingRewards {
    /**
     * @notice checks whether the staking of a LP token is supported by the reward scheme
     * @param lpToken address of LP Token contract
     * @return true if the reward scheme supports `lpToken`, false otherwise
     */
    function isSupported(address lpToken) external returns (bool);

    /**
     * @param user user address
     * @return list of addresses of LP user has engaged in
     */
    function getUserEngagedPool(address user) external view returns (address[] memory);

    /**
     * @return list of addresses of LP registered in this contract
     */
    function getPoolList() external view returns (address[] memory);

    /**
     * @return amount of FLURRY distrubuted for all LP per block,
     * to be shared by the staking pools according to allocation points
     */
    function rewardsRate() external view returns (uint256);

    /**
     * @notice Admin function - set rewards rate earned for all LP per block
     * @param newRewardsRate amount of FLURRY (in wei) per block
     */
    function setRewardsRate(uint256 newRewardsRate) external;

    /**
     * @notice Retrieve the stake balance for a stakeholder.
     * @param addr Stakeholder address
     * @param lpToken Address of LP Token contract
     * @return user staked amount (in wei)
     */
    function stakeOf(address addr, address lpToken) external view returns (uint256);

    /**
     * @notice A method to allow a stakeholder to check his rewards for one LP token
     * @param user The stakeholder to check rewards for
     * @param lpToken Address of LP Token contract
     * @return Accumulated rewards of addr holder (in wei)
     */
    function rewardOf(address user, address lpToken) external view returns (uint256);

    /**
     * @notice A method to allow a stakeholder to check his rewards earned for all LP token
     * @param user The stakeholder to check rewards for
     * @return Accumulated rewards of addr holder (in wei)
     */
    function totalRewardOf(address user) external view returns (uint256);

    /**
     * @notice A method to allow a stakeholder to check his claimble rewards for all LP token
     * @param user The stakeholder to check rewards for
     * @return Accumulated rewards of addr holder (in wei)
     */
    function totalClaimableRewardOf(address user) external view returns (uint256);

    /**
     * @notice A method to add a stake.
     * @param lpToken Address of LP Token contract
     * @param amount amount of flurry tokens to be staked (in wei)
     */
    function stake(address lpToken, uint256 amount) external;

    /**
     * @notice NOT for external use
     * @dev allows Flurry Staking Rewards contract to claim rewards for one LP on behalf of a user
     * @param onBehalfOf address of the user to claim rewards for
     * @param lpToken Address of LP Token contract
     */
    function claimReward(address onBehalfOf, address lpToken) external;

    /**
     * @notice A method to allow a LP token holder to claim his rewards for one LP token
     * @param lpToken Address of LP Token contract
     * Note: If stakingRewards contract do not have enough tokens to pay,
     * this will fail silently and user rewards remains as a credit in this contract
     */
    function claimReward(address lpToken) external;

    /**
     * @notice NOT for external use
     * @dev allows Flurry Staking Rewards contract to claim rewards for all LP on behalf of a user
     * @param onBehalfOf address of the user to claim rewards for
     */
    function claimAllReward(address onBehalfOf) external;

    /**
     * @notice A method to allow a LP token holder to claim his rewards for all LP token
     * Note: If stakingRewards contract do not have enough tokens to pay,
     * this will fail silently and user rewards remains as a credit in this contract
     */
    function claimAllReward() external;

    /**
     * @notice A method to unstake.
     * @param lpToken Address of LP Token contract
     * @param amount amount to unstake (in wei)
     */
    function withdraw(address lpToken, uint256 amount) external;

    /**
     * @notice A method to allow a stakeholder to withdraw full stake.
     * @param lpToken Address of LP Token contract
     * Rewards are not automatically claimed. Use claimReward()
     */
    function exit(address lpToken) external;

    /**
     * @notice Total accumulated reward per token
     * @param lpToken Address of LP Token contract
     * @return Reward entitlement per LP token staked (in wei)
     */
    function rewardsPerToken(address lpToken) external view returns (uint256);

    /**
     * @notice current reward rate per LP token staked
     * @param lpToken Address of LP Token contract
     * @return rewards rate in FLURRY per block per LP staked scaled by 18 decimals
     */
    function rewardRatePerTokenStaked(address lpToken) external view returns (uint256);

    /**
     * @notice Admin function - A method to set reward duration
     * @param lpToken Address of LP Token contract
     * @param rewardDuration Reward Duration in number of blocks
     */
    function startRewards(address lpToken, uint256 rewardDuration) external;

    /**
     * @notice Admin function - End Rewards distribution earlier if there is one running
     * @param lpToken Address of LP Token contract
     */
    function endRewards(address lpToken) external;

    /**
     * @return true if rewards are locked for given lpToken, false if rewards are unlocked or if lpTokenis not supported
     * @param lpToken address of LP Token contract
     */
    function isLocked(address lpToken) external view returns (bool);

    /**
     * @notice Admin function - lock rewards for given lpToken
     * @param lpToken address of the lpToken contract
     * @param lockDuration lock duration in number of blocks
     */
    function setTimeLock(address lpToken, uint256 lockDuration) external;

    /**
     * @notice Admin function - lock rewards for given lpToken until a specific block
     * @param lpToken address of the lpToken contract
     * @param lockEndBlock lock rewards until specific block no.
     */
    function setTimeLockEndBlock(address lpToken, uint256 lockEndBlock) external;

    /**
     * @notice Admin function - lock all lpToken rewards
     * @param lockDuration lock duration in number of blocks
     */
    function setTimeLockForAllLPTokens(uint256 lockDuration) external;

    /**
     * @notice Admin function - lock all lpToken rewards until a specific block
     * @param lockEndBlock lock rewards until specific block no.
     */
    function setTimeLockEndBlockForAllLPTokens(uint256 lockEndBlock) external;

    /**
     * @notice Admin function - unlock rewards for given lpToken
     * @param lpToken address of the lpToken contract
     */
    function earlyUnlock(address lpToken) external;

    /**
     * @param lpToken address of the lpToken contract
     * @return the current lock end block number
     */
    function getLockEndBlock(address lpToken) external view returns (uint256);

    /**
     * @notice Admin function - register a LP to this contract
     * @param lpToken address of the LP to be registered
     * @param allocPoint allocation points (weight) assigned to the given LP
     */
    function addLP(address lpToken, uint256 allocPoint) external;

    /**
     * @notice Admin function - change the allocation points of a LP registered in this contract
     * @param lpToken address of the LP subject to change
     * @param allocPoint allocation points (weight) assigned to the given LP
     */
    function setLP(address lpToken, uint256 allocPoint) external;

    /**
     * @notice Admin function - withdraw random token transfer to this contract
     * @param token ERC20 token address to be sweeped
     * @param to address for sending sweeped tokens to
     */
    function sweepERC20Token(address token, address to) external;

    /**
     * @return reference to RhoToken Rewards contract
     */
    function flurryStakingRewards() external returns (IFlurryStakingRewards);
}
