// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC20.sol";

interface IPool {
    /*///////////////////////////////////////////////////////////////
                            STRUCTS/ENUMS
    ///////////////////////////////////////////////////////////////*/

    enum Status {
        Uninitialized,
        Created,
        Approved,
        Rejected,
        Seeding,
        Locked,
        Unlocked
    }

    struct StakingSchedule {
        /// @notice The timestamp when the seeding period starts.
        uint256 seedingStart;
        /// @notice The duration of the seeding period.
        uint256 seedingPeriod;
        /// @notice The timestamp when the locked period starts.
        uint256 lockedStart;
        /// @notice The duration of the lock period, which is also the duration of rewards.
        uint256 lockPeriod;
        /// @notice The timestamp when the rewards period ends.
        uint256 periodFinish;
    }

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    ///////////////////////////////////////////////////////////////*/

    error StakeLimitMismatch();

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    ///////////////////////////////////////////////////////////////*/

    event PoolInitialized(
        address indexed token,
        address indexed creator,
        uint256 seedingPeriod,
        uint256 lockPeriod,
        uint256 amount,
        uint256 fee,
        uint256 maxStakePerAddress,
        uint256 maxStakePerPool
    );

    event PoolApproved();

    event PoolRejected();

    event PoolStarted(uint256 seedingStart, uint256 periodFinish);

    event RewardsRetrieved(address indexed creator, uint256 amount);

    event Staked(address indexed account, uint256 amount);

    event Unstaked(address indexed account, uint256 amount);

    event RewardPaid(address indexed account, uint256 amount);

    event ProtocolFeePaid(address indexed treasury, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                            INITIALIZER
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes a new staking pool
     * @param _creator The address of pool creator
     * @param _treasury The address of the treasury where the rewards will be distributed
     * @param _token The address of the token to be staked
     * @param _seedingPeriod The period in seconds during which users are able to stake
     * @param _lockPeriod The period in seconds during which the staked tokens are locked
     * @param _maxStakePerAddress The maximum amount of tokens that can be staked by a single address
     * @param _protocolFeeBps The fee charged by the protocol for each pool in bps
     * @param _maxStakePerPool The maximum amount of tokens that can be staked in the pool
     */
    function initialize(
        address _creator,
        address _treasury,
        address _token,
        uint256 _seedingPeriod,
        uint256 _lockPeriod,
        uint256 _maxStakePerAddress,
        uint256 _protocolFeeBps,
        uint256 _maxStakePerPool
    ) external;

    /*///////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the registry this pool is setup with
     */
    function registry() external view returns (address);

    /**
     * @notice Returns the current operational status of the pool.
     * @return The current status of the pool.
     */
    function status() external view returns (Status);

    /**
     * @notice Returns the earned rewards of a specific account
     * @param account The address of the account
     * @return The amount of rewards earned by the account
     */
    function earned(address account) external view returns (uint256);

    /**
     * @notice Calculates the rewards per token for the current time.
     * @dev The total amount of rewards available in the system is fixed, and it needs to be distributed among the users
     * based on their token balances and the lock duration.
     * Rewards per token represent the amount of rewards that each token is entitled to receive at the current time.
     * The calculation takes into account the reward rate (rewardAmount / lockPeriod), the time duration since the last
     * update,
     * and the total supply of tokens in the pool.
     * @return The updated rewards per token value for the current block.
     */
    function rewardPerToken() external view returns (uint256);

    /**
     * @notice Get the last time where rewards are applicable.
     * @return The last time where rewards are applicable.
     */
    function lastTimeRewardApplicable() external view returns (uint256);

    /**
     * @notice Get the token used in the pool
     * @return The ERC20 token used in the pool
     */
    function token() external view returns (IERC20);

    /*///////////////////////////////////////////////////////////////
    					MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Approves the pool to start accepting stakes
    function approvePool() external;

    /// @notice Rejects the pool
    function rejectPool() external;

    /// @notice Retrieves the reward tokens from the pool if the pool is rejected
    function retrieveRewardToken() external;

    /// @notice Starts the seeding period for the pool, during which deposits are accepted
    function start() external;

    /**
     * @notice Stakes a certain amount of tokens
     * @param _amount The amount of tokens to stake
     */
    function stake(uint256 _amount) external;

    /**
     * @notice Stakes a certain amount of tokens for a specified address
     * @param _staker The address for which the tokens are being staked
     * @param _amount The amount of tokens to stake
     */
    function stakeFor(address _staker, uint256 _amount) external;

    /**
     * @notice Unstakes all staked tokens
     */
    function unstakeAll() external;

    /**
     * @notice Claims the earned rewards
     */
    function claim() external;
}
