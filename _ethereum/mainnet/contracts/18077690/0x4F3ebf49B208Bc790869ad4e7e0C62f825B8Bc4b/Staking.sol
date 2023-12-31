// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./IStaking.sol";

contract Staking is Ownable, IStaking {
    using SafeERC20 for IERC20;

    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardsToken;
    uint public immutable emergencyWithdrawPercentage;
    address public immutable emergencyWithdrawAddress;

    bool public rewardsNotified;
    // Duration of rewards to be paid out (in seconds)
    uint public immutable duration;
    // Timestamp of when the staking starts
    uint public immutable startAt;
    // Timestamp of when the rewards finish
    uint public immutable finishAt;
    // Minimum of last updated time and reward finish time
    uint public updatedAt;
    // Reward to be paid out per second
    uint public rewardRate;
    // Sum of (reward rate * dt * 1e18 / total supply)
    uint public rewardPerTokenStored;
    // Maximum amount a single user can stake;
    uint public immutable maxAmountUserCanStake;
    // Total rewrads that will be distributed.
    uint public totalRewards;

    // User address => rewardPerTokenStored
    mapping(address => uint) public userRewardPerTokenPaid;
    // User address => rewards to be claimed
    mapping(address => uint) public rewards;

    // Total staked
    uint public totalSupply;
    // User address => staked amount
    mapping(address => uint) public balanceOf;

    constructor(
        address _stakingToken,
        address _rewardToken,
        address _emergencyWithdrawAddress,
        uint _emergencyWithdrawPercentage,
        uint _maxAmountUserCanStake,
        uint _startAt,
        uint _finishAt
    ) {
        if (_startAt >= _finishAt) {
            revert StartIsGreaterThanFinish(_startAt, _finishAt);
        }

        if (_emergencyWithdrawPercentage > 10000) {
            revert PercentageOutOfRange(_emergencyWithdrawPercentage);
        }

        if (_maxAmountUserCanStake == 0) {
            revert AmountIsZero();
        }

        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardToken);
        maxAmountUserCanStake = _maxAmountUserCanStake;
        startAt = _startAt;
        finishAt = _finishAt;
        duration = _finishAt - _startAt;
        emergencyWithdrawPercentage = _emergencyWithdrawPercentage;
        emergencyWithdrawAddress = _emergencyWithdrawAddress;
    }

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();

        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }

        _;
    }

    modifier isOpen() {
        if (block.timestamp < startAt || block.timestamp > finishAt) {
            revert StakePoolClosed();
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        uint minFinishStart = _min(finishAt, block.timestamp);
        return startAt > minFinishStart ? 0 : minFinishStart;
    }

    function rewardPerToken() public view returns (uint) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }

        uint res = rewardPerTokenStored +
            (rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18) /
            totalSupply;

        return res;
    }

    function stake(uint _amount) external isOpen updateReward(msg.sender) {
        _stake(_amount);
    }

    function _stake(uint _amount) internal {
        if (_amount == 0) {
            revert AmountIsZero();
        }

        uint amount = _amount + balanceOf[msg.sender];

        if (amount > maxAmountUserCanStake) {
            revert MaxAmountSuperceeded(amount);
        }

        uint balanceBefore = stakingToken.balanceOf(address(this));

        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

        uint balanceAfter = stakingToken.balanceOf(address(this));

        uint amountAfterTransfer = balanceAfter - balanceBefore;

        balanceOf[msg.sender] += amountAfterTransfer;
        totalSupply += amountAfterTransfer;
        emit TokensStaked(msg.sender, amountAfterTransfer);
    }

    function withdraw(uint _amount) external {
        _withdraw(_amount);
    }

    function _withdraw(uint _amount) internal updateReward(msg.sender) {
        if (_amount == 0) {
            revert AmountIsZero();
        }
        if (block.timestamp < finishAt) {
            revert TokensAreLockedUntilFinish(finishAt);
        }

        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        stakingToken.safeTransfer(msg.sender, _amount);
        emit TokensWithdrawn(msg.sender, _amount);
    }

    function emergencyWithdraw(uint _amount) public updateReward(msg.sender) {
        if (_amount == 0) {
            revert AmountIsZero();
        }

        uint balance = balanceOf[msg.sender];
        if (balance == 0) {
            revert BalanceIsZero();
        }

        if (balance < _amount) {
            revert AmountIsMoreThanBalance(balance, _amount);
        }

        uint amount = 0;
        uint fee = 0;
        if (block.timestamp < finishAt) {
            fee = (_amount * emergencyWithdrawPercentage) / 10_000;
            amount = _amount - fee;
        } else {
            amount = _amount;
        }

        balanceOf[msg.sender] -= amount + fee;
        totalSupply -= amount + fee;
        stakingToken.safeTransfer(msg.sender, amount);
        if (fee > 0) {
            stakingToken.transfer(emergencyWithdrawAddress, fee);
        }

        emit EmergencyWithdraw(msg.sender, amount, fee);
    }

    function earned(address _account) public view returns (uint) {
        return
            ((balanceOf[_account] *
                (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e18) +
            rewards[_account];
    }

    function getReward() public updateReward(msg.sender) {
        address user = msg.sender;
        uint reward = rewards[user];
        if (reward > 0) {
            rewards[user] = 0;
            rewardsToken.safeTransfer(user, reward);
        }

        emit RewardsWithdrawn(user, reward);
    }

    function exit() external {
        if (block.timestamp < finishAt) {
            emergencyWithdraw(balanceOf[msg.sender]);
        } else {
            _withdraw(balanceOf[msg.sender]);
        }
        getReward();
    }

    function withdrawLeftover() external onlyOwner {
        // Can't withdraw leftovers until 7 days have passed since the end
        if (block.timestamp < finishAt + 604800) {
            revert RewardPeriodNotFinished(startAt, finishAt);
        }
        uint leftover = rewardsToken.balanceOf(address(this));
        if (leftover > 0) {
            rewardsToken.safeTransfer(owner(), leftover);
        }
    }

    function notifyRewardAmount(
        uint _amount
    ) external onlyOwner updateReward(address(0)) {
        if (_amount == 0) {
            revert AmountIsZero();
        }

        if (block.timestamp > finishAt) {
            revert RewardPeriodFinished(startAt, finishAt);
        }
        if (rewardsNotified) {
            revert RewardsAlreadyNotified();
        }

        rewardsNotified = true;

        uint currentTime = block.timestamp > startAt
            ? block.timestamp
            : startAt;
        rewardRate = _amount / duration;

        if (rewardRate == 0) {
            revert RewardRateIsZero();
        }

        uint balance = rewardsToken.balanceOf(address(this));

        if (rewardRate * duration > balance) {
            revert RewardRateIsMoreThanBalance(balance, rewardRate);
        }

        updatedAt = currentTime;
        totalRewards = _amount;

        emit NotifiedRewards(_amount);
    }

    function _min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }
}
