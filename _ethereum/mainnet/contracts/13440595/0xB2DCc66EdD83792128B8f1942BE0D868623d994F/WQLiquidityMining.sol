// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import "./AccessControlUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./UUPSUpgradeable.sol";

contract WQLiquidityMining is
    Initializable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');
    bytes32 public constant UPGRADER_ROLE = keccak256('UPGRADER_ROLE');

    // Staker contains info related to each staker.
    struct Staker {
        uint256 amount; // amount of tokens currently staked to the contract
        uint256 rewardAllowed; // amount of tokens
        uint256 rewardDebt; // value needed for correct calculation staker's share
        uint256 distributed; // amount of distributed earned tokens
    }

    // StakeInfo contains info related to stake.
    struct StakeInfo {
        uint256 startTime;
        uint256 rewardTotal;
        uint256 distributionTime;
        uint256 totalStaked;
        uint256 totalDistributed;
        address stakeTokenAddress;
        address rewardTokenAddress;
    }

    // Stakers info by token holders.
    mapping(address => Staker) public stakes;

    // ERC20 token staked to the contract.
    IERC20Upgradeable public stakeToken;

    // ERC20 token earned by stakers as reward.
    IERC20Upgradeable public rewardToken;

    /// @notice Common contract configuration variables
    /// @notice Time of start staking
    uint256 public startTime;
    /// @notice Increase of rewards per distribution time
    uint256 public rewardTotal;
    /// @notice Distribution time
    uint256 public distributionTime;

    uint256 public tokensPerStake;
    uint256 public rewardProduced;
    uint256 public allProduced;
    uint256 public producedTime;
    uint256 public totalStaked;
    uint256 public totalDistributed;

    bool public stakingPaused;
    bool public unstakingPaused;
    bool public claimingPaused;
    bool public paused;

    event Staked(uint256 amount, uint256 time, address indexed sender);
    event Claimed(uint256 amount, uint256 time, address indexed sender);
    event Unstaked(uint256 amount, uint256 time, address indexed sender);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        uint256 _startTime,
        uint256 _rewardTotal,
        uint256 _distributionTime,
        address _rewardToken,
        address _stakeToken
    ) public initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        startTime = _startTime;
        producedTime = _startTime;
        rewardTotal = _rewardTotal;
        distributionTime = _distributionTime;
        rewardToken = IERC20Upgradeable(_rewardToken);
        stakeToken = IERC20Upgradeable(_stakeToken);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
        _setRoleAdmin(UPGRADER_ROLE, ADMIN_ROLE);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    /**
     * @dev stake `amount` of tokens to the contract
     *
     * Parameters:
     *
     * - `_amount` - stake amount
     */
    function stake(uint256 _amount) external nonReentrant {
        require(!stakingPaused, 'WQLiquidityMining: Staking is paused');
        require(
            block.timestamp > startTime,
            'WQLiquidityMining: Staking time has not come yet'
        );
        Staker storage staker = stakes[msg.sender];
        if (totalStaked > 0) {
            update();
        }
        staker.rewardDebt += (_amount * tokensPerStake) / 1e20;
        totalStaked += _amount;
        staker.amount += _amount;
        stakeToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Staked(_amount, block.timestamp, msg.sender);
    }

    /**
     * @dev unstake - return staked amount
     *
     * Parameters:
     *
     * - `_amount` - stake amount
     */

    function unstake(uint256 _amount) external nonReentrant {
        require(!unstakingPaused, 'WQLiquidityMining: Unstaking is paused');
        Staker storage staker = stakes[msg.sender];
        require(
            staker.amount >= _amount,
            'WQLiquidityMining: Not enough tokens to unstake'
        );
        update();
        staker.rewardAllowed += (_amount * tokensPerStake) / 1e20;
        staker.amount -= _amount;
        totalStaked -= _amount;
        stakeToken.safeTransfer(msg.sender, _amount);
        emit Unstaked(_amount, block.timestamp, msg.sender);
    }

    /**
     * @dev claim available rewards
     */
    function claim() external nonReentrant {
        require(!claimingPaused, 'WQLiquidityMining: Claiming is paused');
        if (totalStaked > 0) {
            update();
        }
        uint256 reward = calcReward(msg.sender, tokensPerStake);
        require(reward > 0, 'WQLiquidityMining: Nothing to claim');
        Staker storage staker = stakes[msg.sender];
        staker.distributed += reward;
        totalDistributed += reward;

        rewardToken.safeTransfer(msg.sender, reward);
        emit Claimed(reward, block.timestamp, msg.sender);
    }

    /**
     * @dev calcReward - calculates available reward
     */
    function calcReward(address _staker, uint256 _tps)
        private
        view
        returns (uint256 reward)
    {
        Staker storage staker = stakes[_staker];

        reward =
            ((staker.amount * _tps) / 1e20) +
            staker.rewardAllowed -
            staker.distributed -
            staker.rewardDebt;

        return reward;
    }

    /**
     * @dev getClaim - returns available reward of `_staker`
     */
    function getClaim(address _staker) public view returns (uint256 reward) {
        uint256 _tps = tokensPerStake;
        if (totalStaked > 0) {
            uint256 rewardProducedAtNow = produced();
            if (rewardProducedAtNow > rewardProduced) {
                uint256 producedNew = rewardProducedAtNow - rewardProduced;
                _tps += (producedNew * 1e20) / totalStaked;
            }
        }
        reward = calcReward(_staker, _tps);

        return reward;
    }

    /**
     * @dev Calculates the necessary parameters for staking
     *
     */
    function produced() private view returns (uint256) {
        return
            allProduced +
            (rewardTotal * (block.timestamp - producedTime)) /
            distributionTime;
    }

    function update() public {
        require(!paused, 'WQLiquidityMining: Updating is paused');
        uint256 rewardProducedAtNow = produced();
        if (rewardProducedAtNow > rewardProduced) {
            uint256 producedNew = rewardProducedAtNow - rewardProduced;
            if (totalStaked > 0) {
                tokensPerStake += (producedNew * 1e20) / totalStaked;
            }
            rewardProduced = rewardProducedAtNow;
        }
    }

    /**
     * @dev getInfoByAddress - return information about the staker
     */
    function getInfoByAddress(address user)
        external
        view
        returns (
            uint256 staked_,
            uint256 claim_,
            uint256 _balance
        )
    {
        Staker storage staker = stakes[user];
        staked_ = staker.amount;
        claim_ = getClaim(user);
        return (staked_, claim_, stakeToken.balanceOf(user));
    }

    /**
     * @dev Return information about the stake
     */
    function getStakingInfo() external view returns (StakeInfo memory info_) {
        info_ = StakeInfo({
            startTime: startTime,
            rewardTotal: rewardTotal,
            distributionTime: distributionTime,
            totalStaked: totalStaked,
            totalDistributed: totalDistributed,
            stakeTokenAddress: address(stakeToken),
            rewardTokenAddress: address(rewardToken)
        });
        return info_;
    }

    /**
     * @dev Update distribution rewards and remember old values
     */
    function updateReward(uint256 _rewardTotal) external onlyRole(ADMIN_ROLE) {
        allProduced = produced();
        producedTime = block.timestamp;
        rewardTotal = _rewardTotal;
    }

    /**
     * @dev Set start time when staking has not started yet
     */
    function setStartTime(uint256 _startTime) external onlyRole(ADMIN_ROLE) {
        require(
            block.timestamp < startTime,
            'WQLiquidityMining: Staking time has already come'
        );
        startTime = _startTime;
    }

    /**
     * @dev Allows to update 'tokens per stake' parameter
     * @param _tps Specifeies the new tokens per stake value
     */
    function updateTps(uint256 _tps) external onlyRole(ADMIN_ROLE) {
        tokensPerStake = _tps;
    }

    /**
     * @dev Allows to update the value of produced reward
     * @param _rewardProduced Specifeies the new value of rewards produced
     */
    function updateRewardProduced(uint256 _rewardProduced)
        external
        onlyRole(ADMIN_ROLE)
    {
        rewardProduced = _rewardProduced;
    }

    /**
     * @dev Allows to update the daily reward parameter
     * @param _rewardTotal Specifeies the new daily reward value
     */
    function updateRewardTotal(uint256 _rewardTotal)
        external
        onlyRole(ADMIN_ROLE)
    {
        rewardTotal = _rewardTotal;
    }

    /**
     * @dev Allows to update the value of staked tokens
     * @param _totalStaked Specifeies the new value of totally staked tokens
     */
    function updateTotalStaked(uint256 _totalStaked)
        external
        onlyRole(ADMIN_ROLE)
    {
        totalStaked = _totalStaked;
    }

    /**
     * @dev Allows to update the value of distributed rewards
     * @param _totalDistributed Specifeies the new value of totally distributed rewards
     */
    function updateTotalDistributed(uint256 _totalDistributed)
        external
        onlyRole(ADMIN_ROLE)
    {
        totalDistributed = _totalDistributed;
    }

    /**
     * @dev Update user information
     */
    function updateStakerInfo(
        address _user,
        uint256 _amount,
        uint256 _rewardAllowed,
        uint256 _rewardDebt,
        uint256 _distributed
    ) external onlyRole(ADMIN_ROLE) {
        Staker storage staker = stakes[_user];

        staker.amount = _amount;
        staker.rewardAllowed = _rewardAllowed;
        staker.rewardDebt = _rewardDebt;
        staker.distributed = _distributed;
    }

    /**
     * @dev Pause staking
     */
    function stakingPause(bool _paused) external onlyRole(ADMIN_ROLE) {
        stakingPaused = _paused;
    }

    /**
     * @dev Pause unstaking
     */
    function unstakingPause(bool _paused) external onlyRole(ADMIN_ROLE) {
        unstakingPaused = _paused;
    }

    /**
     * @dev Unpause claiming
     */
    function claimingPause(bool _paused) external onlyRole(ADMIN_ROLE) {
        claimingPaused = _paused;
    }

    /**
     * @dev Pause all
     */
    function updatingPause(bool _paused) external onlyRole(ADMIN_ROLE) {
        paused = _paused;
    }

    /**
     * @dev Removes any token from the contract by its address
     * @param _token Token address
     * @param _to Recipient address
     * @param _amount An amount to be removed from the contract
     */
    function removeTokenByAddress(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyRole(ADMIN_ROLE) {
        require(_to != address(0), 'Invalid recipient address');
        IERC20Upgradeable(_token).safeTransfer(_to, _amount);
    }
}
