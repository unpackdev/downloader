// SPDX-License-Identifier: MIT
import "./Math.sol";
import "./IERC20Detailed.sol";
import "./IRewardDistributionRecipient.sol";
import "./LPTokenWrapper.sol";

// solhint-enable max-line-length
pragma solidity >=0.6.0 <0.8.0;

contract BasedRewards is LPTokenWrapper, IRewardDistributionRecipient {
    IERC20Detailed public blo;
    uint256 public duration;

    uint256 public initreward;
    uint256 public starttime;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public totalRewards = 0;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

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

    constructor (
        address _b, // staking token address
        address _blo, // reward token address
        uint256 _duration, // reward duration (endTimestamp - startTimestamp)
        uint256 _initreward, // total reward amount
        uint256 _starttime // reward start time
    ) public LPTokenWrapper(_b) {
        blo = IERC20Detailed(_blo);

        duration = _duration;
        starttime = _starttime;
        notifyRewardAmount(_initreward);
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        if (block.timestamp > starttime) {
            return Math.min(block.timestamp, periodFinish);
        }
        return starttime;
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

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 amount) public override updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public override updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
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
            blo.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
            totalRewards = totalRewards.add(reward);
        }
    }

    modifier checkStart(){
        require(block.timestamp > starttime, "Not started");
        _;
    }

    function notifyRewardAmount(uint256 reward)
        internal
        override
        updateReward(address(0))
    {
        rewardRate = reward.div(duration);
        initreward = reward;
        lastUpdateTime = starttime;
        periodFinish = starttime.add(duration);
        emit RewardAdded(reward);
    }
}
