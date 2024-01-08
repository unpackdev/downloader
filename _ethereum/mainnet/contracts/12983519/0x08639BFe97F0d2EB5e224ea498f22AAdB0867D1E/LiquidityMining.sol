// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Math.sol";

contract LiquidityMining is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public rewardToken;
    IERC20 public stakingToken;

    constructor(
        address _stakingToken,
        uint256 _initreward,
        uint256 _startTime,
        uint256 _duration
    ) {
        require(
            _stakingToken != address(0),
            "StakingRewards: stakingToken cannot be null"
        );
        require(_initreward != 0, "StakingRewards: initreward cannot be null");
        require(_duration != 0, "StakingRewards: duration cannot be null");

        rewardToken = IERC20(_stakingToken);
        stakingToken = IERC20(_stakingToken);
        initreward = _initreward;
        starttime = _startTime;
        DURATION = (_duration * 24 hours);

        _notifyRewardAmount(_initreward);
    }

    uint256 public DURATION;

    uint256 public initreward;
    uint256 public starttime;
    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
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

    function earned(address account) public view returns (uint256) {
        return
            _balances[account]
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e36)
                .add(rewards[account]);
    }

    function deposit(uint256 amount)
        external
        nonReentrant
        updateReward(msg.sender)
        checkStart
    {
        require(amount > 0, "StakingRewards: cannot stake 0");
        require(
            stakingToken.balanceOf(msg.sender) >= amount,
            "Insufficient amount for deposit"
        );

        _stake(amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount)
        public
        nonReentrant
        updateReward(msg.sender)
        checkStart
    {
        require(amount > 0, "StakingRewards: Cannot withdraw 0");
        require(
            _balances[msg.sender] >= amount,
            "Insufficient amount for withdraw"
        );

        _withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    function getReward()
        public
        nonReentrant
        updateReward(msg.sender)
        checkStart
    {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    modifier checkStart() {
        require(block.timestamp >= starttime, "StakingRewards: not start");
        _;
    }

    function emergencyWithdraw(uint256 amount) external nonReentrant {
        require(amount > 0, "StakingRewards: Cannot withdraw 0");
        require(
            _balances[msg.sender] >= amount,
            "Insufficient amount for emergency Withdraw"
        );

        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function _stake(uint256 _amount) private {
        _totalSupply = _totalSupply.add(_amount);
        _balances[msg.sender] = _balances[msg.sender].add(_amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
    }

    function _withdraw(uint256 _amount) private {
        _totalSupply = _totalSupply.sub(_amount);
        _balances[msg.sender] = _balances[msg.sender].sub(_amount);
        stakingToken.safeTransfer(msg.sender, _amount);
    }

    function _notifyRewardAmount(uint256 reward)
        internal
        updateReward(address(0))
    {
        rewardRate = reward.mul(1e18).div(DURATION);
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(reward);
    }

    function dailyRewardApy() external view returns (uint256) {
        uint256 dailyReward = rewardRate.div(1e18);
        return (dailyReward.mul(86400));
    }
}
