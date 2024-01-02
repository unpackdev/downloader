// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// slither-disable-start timestamp
// solhint-disable max-states-count

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Initializable.sol";

import "./IPool.sol";
import "./Error.sol";

contract Pool is IPool, Initializable {
    using SafeERC20 for IERC20;

    /// @notice The underlying status represents the fundamental status of the pool. This value is set when the pool is
    /// initialized, and may later be updated to 'approved', 'rejected', or 'seeding'. It's important to note that while
    /// this status provides an underlying base for the pool's lifecycle, it does not always reflect the current
    /// operational status of the pool, as the pool's operation can move into locked or unlocked phases over time,
    /// depending on the timestamps related to the seeding and locked periods.
    Status private _underlyingStatus;

    /// @notice The ERC20 token being used for STAKING and REWARDS.
    IERC20 public token;

    /// @notice The treasury address where the rewards are transferred to when pool is rejected.
    address public treasury;
    address public immutable registry;
    address public creator;

    /**
     * @dev StakingInfo struct represents the staking lifecycle. It includes all the timing information about the
     * staking process.
     * This struct is used to reduce the number of state declarations in the contract, due to Solidity limitations on
     * the maximum number of allowed state declarations
     */
    StakingSchedule public stakingSchedule;

    /// @notice The maximum amount of tokens that can be staked in the pool.
    uint256 public maxStakePerPool;

    /**
     * @notice The maximum amount of tokens that can be staked per address.
     * This value should consider the decimals of the token.
     * For example, if the token has 18 decimals and the maximum stake should be 500 tokens,
     * then maxStakePerAddress should be 500 * 1e18.
     */
    uint256 public maxStakePerAddress;

    /// @notice The amount of stakers in the pool.
    uint256 public stakersCount;

    /// @notice The amount of reward tokens distributed during the `locked` period.
    uint256 public rewardAmount;

    /// @notice The fee amount taken by the protocol.
    uint256 public feeAmount;

    /// @notice The amount of protocol fee in basis points (bps) to be paid to the treasury. 1 bps is 0.01%
    uint256 public protocolFeeBps;

    /// @notice The amount of reward tokens distributed per second during the `locked` period.
    uint256 public rewardPerTokenStored;

    /// @notice The total amount of tokens staked in the pool.
    uint256 public totalSupply;

    /// @notice The total amount of tokens locked in the pool.
    uint256 public totalSupplyLocked;

    /// @notice Mapping to store the balances of tokens each account has staked.
    mapping(address => uint256) public balances;

    /// @notice Mapping to store the balances of tokens each account has locked.
    mapping(address => uint256) public balancesLocked;

    /// @notice Mapping to store the reward rate for each user at the time of their latest claimed.
    mapping(address => uint256) public userRewardPerTokenPaid;

    /// @notice The maximum amount the protocol fee can be set to. 10,000 bps is 100%.
    uint256 public constant MAX_PCT = 10_000;

    /*///////////////////////////////////////////////////////////////
                      CONSTRUCTOR / INITIALIZER
    ///////////////////////////////////////////////////////////////*/

    constructor(address _registry) {
        if (_registry == address(0)) revert Error.ZeroAddress();
        registry = _registry;
    }

    modifier onlyRegistry() {
        if (msg.sender != registry) revert Error.Unauthorized();
        _;
    }

    modifier onlyCreator() {
        if (msg.sender != creator) revert Error.Unauthorized();
        _;
    }

    modifier onlyOnCreated() {
        if (_underlyingStatus != Status.Created) revert Error.InvalidStatus();
        _;
    }

    /// @inheritdoc IPool
    function initialize(
        address _creator,
        address _treasury,
        address _token,
        uint256 _seedingPeriod,
        uint256 _lockPeriod,
        uint256 _maxStakePerAddress,
        uint256 _protocolFeeBps,
        uint256 _maxStakePerPool
    ) external initializer {
        if (_creator == address(0)) revert Error.ZeroAddress();
        if (_treasury == address(0)) revert Error.ZeroAddress();
        if (_token == address(0)) revert Error.ZeroAddress();
        if (_seedingPeriod == 0) revert Error.ZeroAmount();
        if (_lockPeriod == 0) revert Error.ZeroAmount();
        if (_maxStakePerAddress == 0) revert Error.ZeroAmount();
        if (_maxStakePerPool <= _maxStakePerAddress) revert StakeLimitMismatch();

        token = IERC20(_token);
        uint256 balance = token.balanceOf(address(this));

        stakingSchedule.seedingPeriod = _seedingPeriod;
        stakingSchedule.lockPeriod = _lockPeriod;
        treasury = _treasury;
        creator = _creator;
        _underlyingStatus = Status.Created;
        maxStakePerAddress = _maxStakePerAddress;
        maxStakePerPool = _maxStakePerPool;

        /// No need to check if the protocol fee is too high as it's already been checked in the factory contract.
        protocolFeeBps = _protocolFeeBps;
        /// Since the factory is handling the token transfer, the contract balance is the reward amount.
        /// Passing this value in the params would be pointless.
        feeAmount = (balance * _protocolFeeBps) / MAX_PCT;
        rewardAmount = balance - feeAmount;

        emit PoolInitialized(
            _token,
            _creator,
            _seedingPeriod,
            _lockPeriod,
            balance,
            _protocolFeeBps,
            _maxStakePerAddress,
            _maxStakePerPool
        );
    }

    /*///////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IPool
     * @dev The status function computes the current operational status of the pool based on the underlying status and
     * the current timestamp in relation to the pool's seeding and locked periods.
     * This function is what external callers should use to understand the current status of the pool.
     */
    function status() public view returns (Status) {
        return _status();
    }

    /// @inheritdoc IPool
    function earned(address account) public view returns (uint256) {
        if (_status() != Status.Locked && _status() != Status.Unlocked) return 0;

        return ((balancesLocked[account] * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18);
    }

    /// @inheritdoc IPool
    function rewardPerToken() public view returns (uint256) {
        // If we haven't been approved yet
        uint256 lastReward = lastTimeRewardApplicable();
        // slither-disable-next-line incorrect-equality
        if (lastReward == 0) {
            return 0;
        }

        // We're still in the seeding phase
        uint256 lockStart = stakingSchedule.lockedStart;
        if (lockStart > lastReward) {
            return 0;
        }

        // No one has deposited yet
        if (totalSupplyLocked == 0) {
            return rewardAmount;
        }

        return (((lastReward - lockStart) * rewardAmount * 1e18) / (stakingSchedule.lockPeriod)) / (totalSupplyLocked);
    }

    /// @inheritdoc IPool
    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < stakingSchedule.periodFinish ? block.timestamp : stakingSchedule.periodFinish;
    }

    /*///////////////////////////////////////////////////////////////
    						MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPool
    function approvePool() external onlyRegistry onlyOnCreated {
        _underlyingStatus = Status.Approved;
        emit PoolApproved();
    }

    /// @inheritdoc IPool
    function rejectPool() external onlyRegistry onlyOnCreated {
        _underlyingStatus = Status.Rejected;
        emit PoolRejected();
    }

    /// @inheritdoc IPool
    function retrieveRewardToken() external onlyCreator {
        if (_underlyingStatus != Status.Rejected) revert Error.PoolNotRejected();
        uint256 balance = token.balanceOf(address(this));
        emit RewardsRetrieved(creator, balance);
        rewardAmount = 0;
        feeAmount = 0;
        token.safeTransfer(creator, balance);
    }

    /// @inheritdoc IPool
    function start() external onlyCreator {
        if (_underlyingStatus != Status.Approved) revert Error.PoolNotApproved();

        _underlyingStatus = Status.Seeding;

        // seeding starts now
        stakingSchedule.seedingStart = block.timestamp;
        stakingSchedule.lockedStart = stakingSchedule.seedingStart + stakingSchedule.seedingPeriod;
        stakingSchedule.periodFinish = stakingSchedule.lockedStart + stakingSchedule.lockPeriod;

        _transferProtocolFee();

        emit PoolStarted(stakingSchedule.seedingStart, stakingSchedule.periodFinish);
    }

    /// @inheritdoc IPool
    function stake(uint256 _amount) external {
        _stake(msg.sender, _amount);
    }

    /// @inheritdoc IPool
    function stakeFor(address _staker, uint256 _amount) external {
        if (_staker == address(0)) revert Error.ZeroAddress();
        _stake(_staker, _amount);
    }

    /// @inheritdoc IPool
    function unstakeAll() external {
        if (_status() != Status.Unlocked) revert Error.WithdrawalsDisabled();

        uint256 amount = balances[msg.sender];
        if (amount == 0) revert Error.ZeroAmount();

        totalSupply -= amount;

        balances[msg.sender] -= amount;

        emit Unstaked(msg.sender, amount);
        token.safeTransfer(msg.sender, amount);
    }

    /// @inheritdoc IPool
    function claim() external {
        rewardPerTokenStored = rewardPerToken();

        uint256 reward = earned(msg.sender);
        userRewardPerTokenPaid[msg.sender] = rewardPerTokenStored;

        if (reward > 0) {
            emit RewardPaid(msg.sender, reward);
            token.safeTransfer(msg.sender, reward);
        }
    }

    /*///////////////////////////////////////////////////////////////
    						INTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    function _stake(address _staker, uint256 _amount) internal {
        if (_status() != Status.Seeding) revert Error.DepositsDisabled();
        if (_amount == 0) revert Error.ZeroAmount();
        if (balances[_staker] + _amount > maxStakePerAddress) revert Error.MaxStakePerAddressExceeded();
        if (totalSupply + _amount > maxStakePerPool) revert Error.MaxStakePerPoolExceeded();

        if (balances[_staker] == 0) stakersCount++;

        totalSupply += _amount;
        totalSupplyLocked += _amount;
        balances[_staker] += _amount;
        balancesLocked[_staker] += _amount;

        emit Staked(_staker, _amount);
        token.safeTransferFrom(msg.sender, address(this), _amount);
    }

    function _status() internal view returns (Status) {
        // The pool is created, rejected or approved but not yet started
        if (
            _underlyingStatus == Status.Created || _underlyingStatus == Status.Rejected
                || _underlyingStatus == Status.Approved
        ) {
            return _underlyingStatus;
        }
        // The pool is in the seeding phase
        else if (_underlyingStatus == Status.Seeding && block.timestamp <= stakingSchedule.lockedStart) {
            return Status.Seeding;
        }
        // The pool is in the locked phase
        else if (
            _underlyingStatus == Status.Seeding && block.timestamp > stakingSchedule.lockedStart
                && block.timestamp <= stakingSchedule.periodFinish
        ) {
            return Status.Locked;
        }
        // The pool is in the unlocked phase
        else if (_underlyingStatus == Status.Seeding && block.timestamp > stakingSchedule.periodFinish) {
            return Status.Unlocked;
        }

        return Status.Uninitialized;
    }

    /**
     * @dev While possible, it is highly improbable for a pool to have zero fees, so we can bypass the gas-consuming
     * check of feeAmount being equal to zero.
     * This optimization is aimed at the majority (> 99%) of scenarios, where an actual fee exists. It enables the
     * caller to save some gas.
     * The rare scenario (< 1%) where no fee is present will still safely execute the transaction, but essentially
     * perform no operation since there's no fee to process.
     */
    function _transferProtocolFee() internal {
        emit ProtocolFeePaid(treasury, feeAmount);
        token.safeTransfer(treasury, feeAmount);
    }
}

// slither-disable-end timestamp
