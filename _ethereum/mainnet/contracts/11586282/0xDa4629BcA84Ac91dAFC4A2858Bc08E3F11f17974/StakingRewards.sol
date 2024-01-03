// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

// Stolen with love from Synthetixio
// https://raw.githubusercontent.com/Synthetixio/synthetix/develop/contracts/StakingRewards.sol

import "./Math.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
import "./TransferHelper.sol";
import "./SafeERC20.sol";
import "./XUSD.sol";
import "./XUS.sol";
import "./ReentrancyGuard.sol";
import "./StringHelpers.sol";

// Inheritance
import "./IStakingRewards.sol";
import "./Pausable.sol";

contract StakingRewards is IStakingRewards, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    /* ========== STATE VARIABLES ========== */

    XUSDStablecoin private XUSD;
    XUSDShares public rewardsToken;
    ERC20 public stakingToken;
    uint256 public periodFinish;

    // Constants for various precisions
    // uint256 private constant PRICE_PRECISION = 1e6;

    // Max reward per second
    uint256 public rewardRate;

    // uint256 public rewardsDuration = 86400 hours;
    uint256 public rewardsDuration = 2592000; // 30 * 86400  (30 days)

    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored = 0;
    uint256 public pool_weight; // This staking pool's percentage of the total XUS being distributed by all pools, 6 decimals of precision

    address public owner_address;
    address public timelock_address; // Governance timelock address

    uint256 public cr_boost_max_multiplier = 3000000; // 6 decimals of precision. 1x = 1000000

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _staking_token_supply = 0;
    mapping(address => uint256) public override balanceOf;

    address private dev_address;
    uint256 private dev_fee;
    uint256 public start_time;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _dev_address,
        uint256 _dev_fee,
        address _rewardsToken,
        address _stakingToken,
        address _xusd_address,
        address _timelock_address,
        uint256 _pool_weight,
        uint256 _start_time
    ) public Owned(msg.sender){
        owner_address = msg.sender;
        dev_address = _dev_address;
        dev_fee = _dev_fee; // 40000/1000000, 4% dev reward

        rewardsToken = XUSDShares(_rewardsToken);
        stakingToken = ERC20(_stakingToken);
        XUSD = XUSDStablecoin(_xusd_address);
        lastUpdateTime = block.timestamp;
        timelock_address = _timelock_address;
        pool_weight = _pool_weight;
        rewardRate = 771604938271604938; // (uint256(2000000e18)).div(30 * 86400); // Base emission rate of 2M XUS over the first month
        rewardRate = rewardRate.mul(pool_weight).div(1e6);

        start_time = _start_time;
    }

    modifier checkStart() {
        require(block.timestamp >= start_time, "not yet");
        _;
    }

    function setStart(uint256 _start_time) external {
        require(msg.sender == owner_address, "unauthorized");
        start_time = _start_time;
    }

    function setPoolWeight(uint256 _weight) external {
        require(msg.sender == owner_address, "unauthorized");
        pool_weight = _weight;
        rewardRate = rewardRate.mul(pool_weight).div(1e6);
    }

    /* ========== VIEWS ========== */

    function totalSupply() external override view returns (uint256) {
        return _staking_token_supply;
    }

    function crBoostMultiplier() public view returns (uint256) {
        uint256 multiplier = uint(1e6).add( (uint(1e6).sub(XUSD.global_collateral_ratio())).mul(cr_boost_max_multiplier.sub(1e6)).div(1e6) );
        return multiplier;
    }

    function stakingDecimals() external view returns (uint256) {
        return stakingToken.decimals();
    }

    function rewardsFor(address account) external view returns (uint256) {
        // You may have use earned() instead, because of the order in which the contract executes 
        return rewards[account];
    }

    function lastTimeRewardApplicable() public override view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public override view returns (uint256) {
        if (_staking_token_supply == 0) {
            return rewardPerTokenStored;
        }
        else {
            return rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(crBoostMultiplier()).mul(1e18).div(1e6).div(_staking_token_supply)
            );
        }
    }

    function earned(address account) public override view returns (uint256) {
        return balanceOf[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function getRewardForDuration() external override view returns (uint256) {
        return rewardRate.mul(rewardsDuration).mul(crBoostMultiplier()).div(1e6);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount) external override nonReentrant notPaused updateReward(msg.sender) checkStart {
        require(amount > 0, "Cannot stake 0");

        _staking_token_supply = _staking_token_supply.add(amount);

        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);

        TransferHelper.safeTransferFrom(address(stakingToken), msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public override nonReentrant updateReward(msg.sender) checkStart {
        require(amount > 0, "Cannot withdraw 0");

        _staking_token_supply = _staking_token_supply.sub(amount);

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);

        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public override nonReentrant updateReward(msg.sender) checkStart {
        uint256 reward = rewards[msg.sender];
        uint256 dev_reward = reward.mul(dev_fee).div(1e6);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.mint_reward(dev_address, dev_reward);
            rewardsToken.mint_reward(msg.sender, reward.sub(dev_reward));
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() external {
        withdraw(balanceOf[msg.sender]);
        getReward();
    }

    function renewIfApplicable() external {
        if (block.timestamp > periodFinish) {
            retroCatchUp();
        }
    }

    // If the period expired, renew it
    function retroCatchUp() internal {
        // halve reward
        rewardRate = rewardRate.mul(50).div(100);

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 num_periods_elapsed = uint256(block.timestamp.sub(periodFinish)) / rewardsDuration; // Floor division to the nearest period
        
        // lastUpdateTime = periodFinish;
        periodFinish = periodFinish.add((num_periods_elapsed.add(1)).mul(rewardsDuration));

        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();

        emit RewardsPeriodRenewed(address(stakingToken));
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setDevInfo(address dev, uint256 fee) external onlyByOwnerOrGovernance {
        dev_address = dev;
        dev_fee = fee;
    }

    // Added to support recovering LP Rewards from other systems to be distributed to holders
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyByOwnerOrGovernance {
        // Cannot recover the staking token or the rewards token
        require(
            tokenAddress != address(stakingToken),
            "Cannot withdraw staking token"
        );
        ERC20(tokenAddress).transfer(owner_address, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyByOwnerOrGovernance {
        require(
            periodFinish == 0 || block.timestamp > periodFinish,
            "Previous rewards period not complete"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    function setMultipliers(uint256 _cr_boost_max_multiplier) external onlyByOwnerOrGovernance {
        require(_cr_boost_max_multiplier >= 1, "Max CR Boost must >= 1");
        cr_boost_max_multiplier = _cr_boost_max_multiplier;
        
        emit MaxCRBoostMultiplier(cr_boost_max_multiplier);
    }

    function initializeDefault() external onlyByOwnerOrGovernance {
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit DefaultInitialization();
    }

    function setRewardRate(uint256 _new_rate) external onlyByOwnerOrGovernance {
        rewardRate = _new_rate;
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        // Need to retro-adjust some things if the period hasn't been renewed, then start a new one
        if (block.timestamp > periodFinish) {
            retroCatchUp();
        }
        else {
            rewardPerTokenStored = rewardPerToken();
            lastUpdateTime = lastTimeRewardApplicable();
        }
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    modifier onlyByOwnerOrGovernance() {
        require(msg.sender == owner_address || msg.sender == timelock_address, "Not admin or timelock");
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event StakeLocked(address indexed user, uint256 amount, uint256 secs);
    event Withdrawn(address indexed user, uint256 amount);
    event WithdrawnLocked(address indexed user, uint256 amount, bytes32 kek_id);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);
    event RewardsPeriodRenewed(address token);
    event DefaultInitialization();
    event MaxCRBoostMultiplier(uint256 multiplier);
}
