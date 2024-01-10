// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.8.12;

import "./Math.sol";
import "./SafeERC20.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

interface IBasePool {
    function totalSupply() external view returns (uint256);

    function balanceOf(address addr) external view returns (uint256);
}

contract VirtualBalanceRewardPool is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    using SafeERC20 for IERC20;

    IERC20 public rewardToken;
    uint256 public constant duration = 7 days;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public queuedRewards = 0;
    uint256 public currentRewards = 0;
    uint256 public historicalRewards = 0;
    uint256 public newRewardRatio = 830;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    address public operator;
    address public basePool;

    constructor() initializer {}

    function initialize(
        address reward_,
        address basePool_
    ) external initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();

        rewardToken = IERC20(reward_);
        basePool = basePool_;
    }

    function totalSupply() public view returns (uint256) {
        return IBasePool(basePool).totalSupply();
    }

    function balanceOf(address addr) public view returns (uint256) {
        return IBasePool(basePool).balanceOf(addr);
    }

    function setOperator(address op_) external onlyOwner {
        operator = op_;
    }

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
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored + (lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18 / totalSupply();
    }

    function earned(address account) public view returns (uint256) {
        return balanceOf(account) * (rewardPerToken() - userRewardPerTokenPaid[account]) / 1e18 + rewards[account];
    }

    //update reward, emit, call linked reward's stake
    function stake(address _account, uint256 amount)
    external
    updateReward(_account)
    {
        require(msg.sender == address(basePool), "!authorized");
        // require(amount > 0, 'VirtualDepositRewardPool: Cannot stake 0');
        emit Staked(_account, amount);
    }

    function withdraw(address _account, uint256 amount)
    public
    updateReward(_account)
    {
        require(msg.sender == address(basePool), "!authorized");
        //require(amount > 0, 'VirtualDepositRewardPool : Cannot withdraw 0');

        emit Withdrawn(_account, amount);
    }

    function getReward(address _account) public updateReward(_account) {
        uint256 reward = earned(_account);
        if (reward > 0) {
            rewards[_account] = 0;
            rewardToken.safeTransfer(_account, reward);
            emit RewardPaid(_account, reward);
        }
    }

    function getReward() external {
        getReward(msg.sender);
    }

    function donate(uint256 _amount) external {
        IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), _amount);
        queuedRewards += _amount;
    }

    function queueNewRewards(uint256 _rewards) external {
        require(msg.sender == operator, "!authorized");

        _rewards += queuedRewards;

        if (block.timestamp >= periodFinish) {
            notifyRewardAmount(_rewards);
            queuedRewards = 0;
            return;
        }

        //et = now - (finish-duration)
        uint256 elapsedTime = block.timestamp - (periodFinish - duration);
        //current at now: rewardRate * elapsedTime
        uint256 currentAtNow = rewardRate * elapsedTime;
        uint256 queuedRatio = currentAtNow * 1000 / _rewards;
        if (queuedRatio < newRewardRatio) {
            notifyRewardAmount(_rewards);
            queuedRewards = 0;
        } else {
            queuedRewards = _rewards;
        }
    }

    function notifyRewardAmount(uint256 reward)
    internal
    updateReward(address(0))
    {
        historicalRewards += reward;
        if (block.timestamp >= periodFinish) {
            rewardRate = reward / duration;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            reward += leftover;
            rewardRate = reward / duration;
        }
        currentRewards = reward;
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + duration;
        emit RewardAdded(reward);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
    }
}
