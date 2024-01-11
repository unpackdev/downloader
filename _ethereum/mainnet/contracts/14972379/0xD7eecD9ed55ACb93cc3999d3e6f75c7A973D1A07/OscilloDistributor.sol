// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ReentrancyGuardUpgradeable.sol";
import "./IERC20Meta.sol";
import "./IDistributor.sol";
import "./PausableUpgradeable.sol";
import "./LibTransfer.sol";


contract OscilloDistributor is IDistributor, ReentrancyGuardUpgradeable, PausableUpgradeable {
    using LibTransfer for IERC20Meta;

    IERC20Meta private _stakingToken;
    IERC20Meta private _rewardToken;

    uint private _totalSupply;
    uint public periodFinish;
    uint public rewardRate;
    uint public rewardsDuration;
    uint public lastUpdateTime;
    uint public rewardPerTokenStored;

    mapping(address => bool) private _whitelist;
    mapping(address => uint) private _balances;
    mapping(address => uint) public rewards;
    mapping(address => uint) public accountRewardPerTokenPaid;

    event Staked(address indexed account, uint amount);
    event Unstaked(address indexed account, uint amount);
    event Claimed(address indexed account, uint amount);
    event RewardsDurationUpdated(uint rewardsDuration);
    event RewardDistributed(uint amount);

    modifier onlyWhitelisted {
        require(msg.sender != address(0) && _whitelist[msg.sender], "!whitelist");
        _;
    }

    modifier onlyGovernance {
        require(msg.sender == address(_stakingToken), "!governance");
        _;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            accountRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /** Initialize **/

    function initialize(address _staking, address _reward) external initializer {
        __ReentrancyGuard_init();
        __PausableUpgradeable_init();

        require(_staking != address(0) && _reward != address(0), "invalid tokens");
        _stakingToken = IERC20Meta(_staking);
        _rewardToken = IERC20Meta(_reward);
        rewardsDuration = 28 days;
    }

    /** Views **/

    function rewardToken() public view override returns (address) {
        return address(_rewardToken);
    }

    function reserves() public view override returns (uint) {
        return _rewardToken.balanceOf(address(this));
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }

    function earned(address account) public view returns (uint) {
        return rewards[account] + (_balances[account] * (rewardPerToken() - accountRewardPerTokenPaid[account]) / 1e18);
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function rewardPerToken() public view returns (uint) {
        if (_totalSupply == 0) return rewardPerTokenStored;
        return rewardPerTokenStored + ((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18 / _totalSupply);
    }

    function rewardForDuration() public view returns (uint) {
        return rewardRate * rewardsDuration;
    }

    /** Interactions **/

    function stake(uint amount) external nonReentrant notPaused updateReward(msg.sender) {
        require(amount > 0, "!amount");
        _totalSupply += amount;
        _balances[msg.sender] += amount;
        _stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function unstake(uint amount) public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "!amount");
        _totalSupply -= amount;
        _balances[msg.sender] -= amount;
        _stakingToken.safeTransfer(msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }

    function claim() public nonReentrant updateReward(msg.sender) {
        uint amount = rewards[msg.sender];
        if (amount > 0) {
            delete rewards[msg.sender];
            _rewardToken.safeTransfer(msg.sender, amount);
            emit Claimed(msg.sender, amount);
        }
    }

    function exit() external {
        uint amount = _balances[msg.sender];
        if (amount > 0) unstake(amount);
        claim();
    }

    /** Restricted **/

    function setWhitelist(address target, bool on) external onlyOwner {
        require(target != address(0), "!target");
        _whitelist[target] = on;
    }

    function setRewardsDuration(uint newRewardsDuration) external onlyOwner {
        require(periodFinish == 0 || block.timestamp > periodFinish, "!duration");
        rewardsDuration = newRewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    function notifyRewardDistributed(uint rewardAmount) external override onlyWhitelisted updateReward(address(0)) {
        _rewardToken.safeTransferFrom(msg.sender, address(this), rewardAmount);
        if (block.timestamp >= periodFinish) {
            rewardRate = rewardAmount / rewardsDuration;
        } else {
            uint remaining = periodFinish - block.timestamp;
            uint leftover = remaining * rewardRate;
            rewardRate = (rewardAmount + leftover) / rewardsDuration;
        }

        uint balance = _rewardToken.balanceOf(address(this));
        require(rewardRate <= balance / rewardsDuration, "!rewardRate");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardsDuration;
        emit RewardDistributed(rewardAmount);
    }

    function stakeBehalf(address account, uint amount) public override onlyGovernance updateReward(account) {
        require(amount > 0 && _stakingToken.balanceOf(address(this)) >= _totalSupply + amount, "!amount");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Staked(account, amount);
    }

    function sweep() external onlyOwner {
        uint leftover = _stakingToken.balanceOf(address(this)) - _totalSupply;
        if (leftover > 0) _stakingToken.safeTransfer(owner(), leftover);
    }
}
