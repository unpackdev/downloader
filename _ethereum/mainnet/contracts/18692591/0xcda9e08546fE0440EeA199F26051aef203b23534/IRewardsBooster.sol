// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

/**
 * @title Asymetrix Protocol V2 IRewardsBooster
 * @author Asymetrix Protocol Inc Team
 * @notice An interface of the RewardsBooster contract.
 */
interface IRewardsBooster {
    /**
     * @notice Initial parameters structure.
     * @param ticket A Ticket contract address.
     * @param stEthOracle An oracle for stETH token.
     * @param asxOracle An oracle for ASX token that returns price of ASX token in WETH.
     * @param nonfungiblePositionManager A NonfungiblePositionManager contract address.
     * @param uniswapWrapper A wrapper contract address that helps to interact with Uniswap V3.
     * @param weth WETH token address.
     * @param asx ASX token address.
     * @param maxBoost A maximum possible boost coefficient. Is used when lock (position) is created by a user.
     * @param minBoostThreshold A threshold (in %) that all of the user's locks (positions) together must overcome for a
     *                          boost to be awarded during a rewards claim on the StakePrizePool contract.
     * @param maxBoostThreshold A threshold (in %) that all of the user's locks (positions) together must achieve to get
     *                          the maximum boost during a rewards claim on the StakePrizePool contract.
     * @param slippageTolerance A slippage tolerance to apply in time of swap of ETH/WETH for ASX.
     */
    struct InitParams {
        address ticket;
        address stEthOracle;
        address asxOracle;
        address nonfungiblePositionManager;
        address uniswapWrapper;
        address weth;
        address asx;
        uint16 maxBoost;
        uint16 minBoostThreshold;
        uint16 maxBoostThreshold;
        uint16 slippageTolerance;
    }

    /**
     * @notice Staking pool structure.
     * @param isFungible Indicates if pool accepts fungible ERC-20 or non fungible ERC-721 tokens.
     * @param stakeToken Token address to stake in the staking pool.
     * @param stakeTokenValuer Valuer for the staked token.
     * @param liquidityPool Liquidity pool where liquidity is stored.
     * @param validator Validator whose main role is to execute different validations in time of stakes and unstakes.
     * @param minLockDuration Minimum look duration in the staking pool.
     * @param maxLockDuration Maximum look duration in the staking pool.
     * @param lockDurationSettingsNumber An amount of settings in the mapping with lock duration settings.
     */
    struct Pool {
        uint256 isFungible;
        address stakeToken;
        address stakeTokenValuer;
        address liquidityPool;
        address validator;
        uint32 minLockDuration;
        uint32 maxLockDuration;
        uint8 lockDurationSettingsNumber;
    }

    /**
     * @notice User structure.
     * @param initializedLocksNumber Number of locks (positions) created and initialized by user.
     */
    struct User {
        uint8 initializedLocksNumber;
    }

    /**
     * @notice Lock (position) structure.
     * @param amountOrId Amount of ERC-20 locked tokens (or ERC-721 NFT locked position ID).
     * @param createdAt Timestamp when the lock (position) was created.
     * @param updatedAt Timestamp when the lock (position) was updated last ime.
     * @param duration Duration of the lock (position).
     * @param maxBoost A maximum possible boost coefficient for user. Is set when lock (position) is created by a user.
     * @param isInitialized Indicates if the lock (position) is initialized or not.
     */
    struct Lock {
        uint256 amountOrId;
        uint32 createdAt;
        uint32 updatedAt;
        uint32 duration;
        uint16 maxBoost;
        bool isInitialized;
    }

    /**
     * @notice LockDurationSettings structure.
     * @param lowerLockDuration Lower lock duration (in seconds).
     * @param upperLockDuration Upper lock duration (in seconds).
     * @param additionalBoost An additional boost that will be applied for locks that are in range of above durations.
     */
    struct LockDurationSettings {
        uint32 lowerLockDuration;
        uint32 upperLockDuration;
        uint16 additionalBoost;
    }

    /**
     * @notice Event emitted when a new lock (position) is created by a user.
     * @param _pid Staking pool ID.
     * @param _user Lock (position) creator address.
     * @param _lid Lock (position) ID.
     * @param _lock Lock (position) structure.
     */
    event LockCreated(uint8 indexed _pid, address indexed _user, uint8 indexed _lid, Lock _lock);

    /**
     * @notice Event emitted when a lock (position) is closed by a user.
     * @param _pid Staking pool ID.
     * @param _user Lock (position) creator address.
     * @param _lid Lock (position) ID.
     */
    event LockClosed(uint8 indexed _pid, address indexed _user, uint8 indexed _lid);

    /**
     * @notice Event emitted when a lock duration was extended.
     * @param _pid Staking pool ID where to extend a lock duration for the position.
     * @param _user Lock (position) creator address.
     * @param _lid An ID of the lock (position) where to extend a lock duration.
     * @param _newDuration A new duration (in seconds) for the lock of the position.
     */
    event LockExtended(uint8 indexed _pid, address indexed _user, uint8 indexed _lid, uint32 _newDuration);

    /**
     * @notice Event emitted when a new staking pool was added by an owner.
     * @param _pid Staking pool ID.
     * @param _pool Staking pool structure.
     */
    event PoolCreated(uint8 indexed _pid, Pool _pool);

    /**
     * @notice Event emitted when accidentally transferred to this contract token (including ETH) was withdrawn
     *         (rescued) by an owner.
     * @param token A token that was withdraw. If token address is equal to zero address - ETH was withdrawn.
     * @param amountOrId An amount of native/ERC-20 tokens or ID of ERC-721 NFT token that was withdraw.
     * @param isFungible Indicates if token that was withdraw is fungible ERC-20 token.
     * @param recipient A recipient of withdrawn tokens.
     */
    event Rescued(address indexed token, uint256 amountOrId, bool indexed isFungible, address indexed recipient);

    /**
     * @notice Calculates a boost coefficient for the array of users.
     * @param _users An array users to calculate boost coefficient for.
     * @return An array with boost coefficients for the users.
     * @return An array with flags that indicate if a user is able to use this coefficient to multiply his rewards.
     */
    function getBoostBatch(address[] calldata _users) external view returns (uint32[] memory, bool[] memory);

    /**
     * @notice Calculates a boost coefficient for a user.
     * @param _user A user to calculate boost coefficient for.
     * @return A boost coefficient for a user.
     * @return A flag that indicates if a user is able to use this coefficient to multiply his rewards.
     */
    function getBoost(address _user) external view returns (uint32, bool);

    /**
     * @notice Returns staking pool info by its ID.
     * @param _pid Staking pool ID.
     * @return Staking pool info.
     */
    function getPoolInfo(uint8 _pid) external view returns (Pool memory);
}
