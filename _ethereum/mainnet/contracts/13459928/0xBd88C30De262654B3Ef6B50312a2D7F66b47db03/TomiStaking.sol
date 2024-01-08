// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import "./Math.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Initializable.sol";


contract TomiStaking is Ownable, ReentrancyGuard, Pausable, Initializable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    address public tomiPool;
    address public tomiGovernance;
    IERC20 public tomi;
    address public rewardsDistribution;
    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public rewardsDuration = 7 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public timestampNotify;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    uint256 private _totalRevenueShared;
    uint256 private _revenueShared;
    uint256 private _accAmountPerRevenueShared;


    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _rewardDebts;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _rewardsDistribution) public {
        rewardsDistribution = _rewardsDistribution;
    }

    function initialize(address _tomiToken, address _tomiPool, address _tomiGovernance) external initializer {
        tomi = IERC20(_tomiToken);
        tomiPool = _tomiPool;
        tomiGovernance = _tomiGovernance;
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(_totalSupply)
            );
    }

    // FE functions
    function earned(address account) public view returns (uint256) {
        return
            _balances[account]
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    // FE functions
    function getRewardRevenueShare(address account)
        public
        view
        returns (uint256)
    {
        if (_balances[account] == 0) return 0;

        return _balances[account].mul(_accAmountPerRevenueShared).sub(_rewardDebts[account]).div(1e18);
    }

    function getTotalRevenueShare() external view returns (uint256) {
        return _totalRevenueShared;
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    function getTotalRewardPool() external view returns (uint256) {
        if (periodFinish <= 0) return 0;
        uint256 remainRewardCommunityPool = (periodFinish.sub(block.timestamp)).mul(rewardRate.mul(rewardsDuration)).div(rewardsDuration);
        return _revenueShared.add(remainRewardCommunityPool);
    }

    function stake(uint256 amount)
        external
        nonReentrant
        whenNotPaused
        updateReward(msg.sender)
    {
        require(amount > 0, "TomiStaking: cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        _rewardDebts[msg.sender] = _balances[msg.sender].mul(_accAmountPerRevenueShared);

        tomi.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount)
        public
        nonReentrant
        updateReward(msg.sender)
    {
        require(amount > 0, "TomiStaking: cannot withdraw 0");
        require(_balances[msg.sender] > 0, "TomiStaking: balance must greater than 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _rewardDebts[msg.sender] = _balances[msg.sender].mul(_accAmountPerRevenueShared);
        tomi.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function claimReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];

        _rewardDebts[msg.sender] = _balances[msg.sender].mul(_accAmountPerRevenueShared);

        if (reward > 0) {
            rewards[msg.sender] = 0;
            tomi.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
        claimReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function updateRevenueShare(uint256 revenueShared) external PoolAndGovernance {
        _totalRevenueShared = _totalRevenueShared.add(revenueShared);
        _revenueShared = _revenueShared.add(revenueShared);
        if (_totalSupply != 0) {
            _accAmountPerRevenueShared = _accAmountPerRevenueShared.add(revenueShared.div(_totalSupply).mul(1e18));
        }
    }

    function setRewardsDuration(uint256 _rewardsDuration)
        external
        onlyRewardsDistribution
    {
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    function notifyRewardAmount(uint256 reward)
        external
        onlyRewardsDistribution
        updateReward(address(0))
    {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = tomi.balanceOf(address(this));
        require(
            rewardRate <= balance.div(rewardsDuration),
            "Provided reward too high"
        );

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
      require (tokenAddress != address(tomi), "TomiStaking: cannot withdraw the staking token");
      IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
    }

    function transferTomiGovernance(address newTomiGovernance) external onlyOwner {
        require(newTomiGovernance != address(0), "New TomiGovernance is the zero address");
        tomiGovernance = newTomiGovernance;
    }

    function transferTomiPool(address newTomiPool) external onlyOwner {
        require(newTomiPool != address(0), "New TomiPool is the zero address");
        tomiPool = newTomiPool;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyRewardsDistribution() {
        require(
            msg.sender == rewardsDistribution,
            "TomiStaking: caller is not reward distribution"
        );
        _;
    }

    modifier PoolAndGovernance() {
        require((msg.sender == tomiPool) || (msg.sender == tomiGovernance), "TomiStaking: caller is not TomiPool or TomiGovernance");
        _;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            uint256 rewardRevenueShared = getRewardRevenueShare(account);
            _revenueShared = _revenueShared.sub(rewardRevenueShared);
            rewards[account] = earned(account).add(rewardRevenueShared);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
            _rewardDebts[account] = rewardRevenueShared;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
}