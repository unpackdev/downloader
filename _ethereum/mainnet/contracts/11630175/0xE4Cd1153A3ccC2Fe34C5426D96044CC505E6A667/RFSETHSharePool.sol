// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Math.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./IShare.sol";
import "./Operator.sol";
import "./StakeToken.sol";

contract RFSETHSharePool is StakeToken, Operator {

    IShare public share;
    uint256 public constant REWARD_ALLOCATION = 250000 * 10 ** 18;
    uint256 public constant DURATION = 365 days;

    uint256 public startTime;
    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    address public fund;
    uint256 public fundAllocationDivisor = 10;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    constructor(address _share, address _token, uint256 _startTime) public {
        share = IShare(_share);
        token = IERC20(_token);
        startTime = _startTime;
        notifyRewardAmount(REWARD_ALLOCATION);
        fund = msg.sender;
    }

    modifier checkStart() {
        require(block.timestamp >= startTime, 'Share Pool: not start');
        _;
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

    function setFund(address newFund) external onlyOperator {
        fund = newFund;
    }

    function setFundAllocationDivisor(uint256 newDivisor) external onlyOperator {
        require(fundAllocationDivisor >= 10, 'Invalid divisor'); // Max. 10%
        fundAllocationDivisor = newDivisor;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function stake(uint256 amount)
        public
        override
        updateReward(msg.sender)
        checkStart
    {
        require(amount > 0, 'SharePool: Cannot stake 0');

        uint256 fundReserve = amount.div(fundAllocationDivisor);
        amount = amount.sub(fundReserve);
        token.transferFrom(msg.sender, fund, fundReserve);

        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount)
        public
        override
        updateReward(msg.sender)
        checkStart
    {
        require(amount > 0, 'SharePool: Cannot withdraw 0');
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public updateReward(msg.sender) checkStart {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            IShare(share).withdraw(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function notifyRewardAmount(uint256 reward) private updateReward(address(0)) {
        if (block.timestamp > startTime) {
            if (block.timestamp >= periodFinish) {
                rewardRate = reward.div(DURATION);
            } else {
                uint256 remaining = periodFinish.sub(block.timestamp);
                uint256 leftover = remaining.mul(rewardRate);
                rewardRate = reward.add(leftover).div(DURATION);
            }
            lastUpdateTime = block.timestamp;
            periodFinish = block.timestamp.add(DURATION);
            emit RewardAdded(reward);
        } else {
            rewardRate = reward.div(DURATION);
            lastUpdateTime = startTime;
            periodFinish = startTime.add(DURATION);
            emit RewardAdded(reward);
        }
    }
}
