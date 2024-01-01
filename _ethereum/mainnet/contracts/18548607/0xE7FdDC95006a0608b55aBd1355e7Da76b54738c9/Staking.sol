//SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./console.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./errors.sol";

contract Staking is ReentrancyGuard, Ownable {
    IERC20 public token;

    bool public isPaused = false;
    uint256 public rewardsPerSecond = 4.1538 ether;
    uint256 public constant stakingAmountToStart = 21 * 10 ** 6 * 10 ** 18; // 21M tokens
    uint256 public totalStaked = 0;

    uint64 public stakingStartTime = 0;
    uint64 public stakingEndTime = 0;
    uint64 public totalUsersWeight = 0;

    mapping(address => Stake) public userStakes;
    mapping(address => uint64) public userWeight;

    struct Stake {
        uint256 deposited;
        uint64 startStaking;
        uint64 timeOfLastUpdate;
        uint256 unclaimedRewards;
    }

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event ClaimRewards(address indexed user, uint256 amount);

    // Constructor function
    constructor(address _initialOwner, address _tokenAddress)
    Ownable(_initialOwner)
    {
        token = IERC20(_tokenAddress);
    }

    modifier whenNotPaused() {
        if (isPaused) {
            revert Staking_IsPaused();
        }
        _;
    }

    modifier whenPaused() {
        if (!isPaused) {
            revert Staking_NotPaused();
        }
        _;
    }

    function pause()
    external
    onlyOwner
    whenNotPaused
    {
        isPaused = true;
    }

    function unpause()
    external
    onlyOwner
    whenPaused
    {
        isPaused = false;
    }

    // Deposit tokens to the contract, start/update staking
    function deposit(uint256 _amount)
    external
    whenNotPaused
    {
        if (_amount == 0) {
            revert Staking_WrongInputUint();
        }
        if (!token.transferFrom(msg.sender, address(this), _amount)) {
            revert Staking_TransferFailed(address(this), _amount);
        }

        if (stakingStartTime == 0 && totalStaked + _amount >= stakingAmountToStart) {
            stakingStartTime = uint64(block.timestamp);
            stakingEndTime = uint64(block.timestamp) + 900 days;
        }

        Stake storage userStake = userStakes[msg.sender];

        if (userStake.deposited == 0) {
            // new staking deposit
            userStake.deposited = _amount;
            userStake.startStaking = uint64(block.timestamp);
            userStake.timeOfLastUpdate = uint64(block.timestamp);
            userStake.unclaimedRewards = 0;
        } else {
            // increase staking deposit
            uint256 rewards = calculateRewards(msg.sender);
            userStake.unclaimedRewards += rewards;
            userStake.deposited += _amount;
            userStake.timeOfLastUpdate = uint64(block.timestamp);
        }

        _updateUserWeight(userStake);

        totalStaked += _amount;
        emit Deposit(msg.sender, _amount);
    }

    // Mints rewards for msg.sender
    function claimRewards()
    external
    nonReentrant
    {
        Stake storage userStake = userStakes[msg.sender];
        uint256 _rewards = calculateRewards(msg.sender) + userStake.unclaimedRewards;
        if (_rewards == 0) {
            revert Staking_NoRewards();
        }
        if (token.balanceOf(address(this)) - totalStaked < _rewards) {
            revert Staking_NoSupplyForRewards();
        }

        userStake.unclaimedRewards = 0;
        userStake.timeOfLastUpdate = uint64(block.timestamp);
        _updateUserWeight(userStake);

        _transferTokens(msg.sender, _rewards);
        emit ClaimRewards(msg.sender, _rewards);
    }

    // Withdraw specified amount of staked tokens
    function withdraw(uint256 _amount)
    external
    nonReentrant
    {
        Stake storage userStake = userStakes[msg.sender];
        if (userStake.deposited < _amount) {
            revert Staking_WithdrawAmount();
        }

        uint256 _rewards = calculateRewards(msg.sender);
        userStake.deposited -= _amount;
        userStake.timeOfLastUpdate = uint64(block.timestamp);
        userStake.unclaimedRewards = _rewards;
        totalStaked -= _amount;

        // reset user multiplier
        userStake.startStaking = uint64(block.timestamp);
        _updateUserWeight(userStake);

        _transferTokens(msg.sender, _amount);

        emit Withdraw(msg.sender, _amount);
    }

    // Withdraw all stake and rewards and mints them to the msg.sender
    function withdrawAll()
    external
    nonReentrant
    {
        Stake storage userStake = userStakes[msg.sender];
        if (userStake.deposited == 0) {
            revert Staking_NoDeposit();
        }

        uint256 _rewards = calculateRewards(msg.sender) + userStake.unclaimedRewards;
        uint256 _deposit = userStake.deposited;

        if (token.balanceOf(address(this)) - totalStaked < _rewards) {
            revert Staking_NoSupplyForRewards();
        }

        // reset reset + reset user multiplier
        userStake.deposited = 0;
        userStake.timeOfLastUpdate = 0;
        userStake.startStaking = uint64(block.timestamp);

        uint256 _amount = _rewards + _deposit;
        totalStaked -= _deposit;

        _updateUserWeight(userStake);
        _transferTokens(msg.sender, _amount);

        emit Withdraw(msg.sender, _amount);
    }

    // Function useful for fron-end that returns user stake and rewards by address
    function getDepositInfo(address _user)
    public
    view
    returns (uint256, uint256)
    {
        Stake storage userStake = userStakes[_user];

        uint256 _stake = userStake.deposited;
        uint256 _rewards = calculateRewards(_user) + userStake.unclaimedRewards;
        return (_stake, _rewards);
    }

    // Calculate the rewards since the last update on Deposit info
    function calculateRewards(address _user)
    internal
    view
    returns (uint256)
    {
        if (stakingStartTime == 0 || totalUsersWeight == 0 || block.timestamp < stakingStartTime) {
            return 0;
        }

        Stake storage userStake = userStakes[_user];

        uint64 _startRewardsTimestamp;
        if (stakingStartTime > userStake.timeOfLastUpdate) {
            _startRewardsTimestamp = stakingStartTime;
        } else {
            _startRewardsTimestamp = userStake.timeOfLastUpdate;
        }

        uint64 _lastRewardsTimestamp;
        if (stakingEndTime > block.timestamp) {
            _lastRewardsTimestamp = uint64(block.timestamp);
        } else {
            _lastRewardsTimestamp = stakingEndTime;
        }

        uint64 _userWeight = _getUserWeight(userStake.deposited, userStake.startStaking);
        uint256 _userWeightInPool = uint256(_userWeight) * 1 ether / uint256(_getTotalUsersWeightUpdated(_user));
        uint256 _rewards = (_userWeightInPool * rewardsPerSecond * uint256(_lastRewardsTimestamp - _startRewardsTimestamp)) / 1 ether;

        // 10% penalty for early withdrawal
        uint64 _stakingDuration = uint64(block.timestamp) - userStake.startStaking;
        if (_stakingDuration < 30 days) {
            _rewards = _rewards * 0.9 ether / 1 ether;
        }

        return _rewards;
    }

    function getApy(address _user)
    external view
    returns (uint256)
    {
        if (stakingStartTime == 0 || block.timestamp >= stakingEndTime || totalUsersWeight == 0 || block.timestamp < stakingStartTime) {
            return 0;
        }

        Stake storage userStake = userStakes[_user];
        uint64 _userWeight = _getUserWeight(userStake.deposited, userStake.startStaking);
        uint256 _userWeightInPool = uint256(_userWeight) * 1 ether / uint256(_getTotalUsersWeightUpdated(_user));
        uint256 _rewards30d = _userWeightInPool * rewardsPerSecond * 30 days;

        return ((_rewards30d / userStake.deposited) * 365 * 100) / 1 ether;
    }

    // -------------------- Private ----------------------

    function getDurationMultiplier(uint64 _duration)
    private pure
    returns (uint256) {
        if (_duration < 90 days) {
            return 1 ether; // 100% for 30 days
        } else if (_duration < 180 days) {
            return 1.5 ether; // 150% for 90 days
        } else if (_duration < 360 days) {
            return 2 ether; // 200% for 180 days
        } else {
            return 2.5 ether; // 250% for 1 year
        }
    }

    function _transferTokens(address _to, uint256 _amount)
    private
    {
        if (!token.transfer(_to, _amount)) {
            revert Staking_TransferFailed(_to, _amount);
        }
    }

    function _getUserWeight(uint256 _deposit, uint64 _startStaking)
    private view
    returns (uint64)
    {
        uint64 _stakingDuration = uint64(block.timestamp) - _startStaking;
        return uint64(((_deposit * getDurationMultiplier(_stakingDuration)) / 1 ether) / 1 ether);
    }

    function _getTotalUsersWeightUpdated(address _user)
    private view
    returns (uint64)
    {
        Stake storage userStake = userStakes[_user];
        uint64 _weightBefore = userWeight[_user];
        uint64 _actualUserWeight = _getUserWeight(userStake.deposited, userStake.startStaking);
        return totalUsersWeight + _actualUserWeight - _weightBefore;
    }

    function _updateUserWeight(Stake storage userStake)
    private
    {
        uint64 _weightBefore = userWeight[msg.sender];
        userWeight[msg.sender] = _getUserWeight(userStake.deposited, userStake.startStaking);

        if (userWeight[msg.sender] > _weightBefore) {
            totalUsersWeight += userWeight[msg.sender] - _weightBefore;
        } else {
            totalUsersWeight -= _weightBefore - userWeight[msg.sender];
        }
    }

}