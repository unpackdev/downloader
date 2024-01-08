// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";

interface IStakingRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    // Mutative

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;
}

// Inheritance
// https://docs.synthetix.io/contracts/RewardsDistributionRecipient
abstract contract RewardsDistributionRecipient is Ownable {
    address public rewardsDistribution;

    modifier onlyRewardsDistribution() {
        require(
            msg.sender == rewardsDistribution,
            "Caller is not RewardsDistribution contract"
        );
        _;
    }

    function setRewardsDistribution(address _rewardsDistribution)
        external
        onlyOwner
    {
        rewardsDistribution = _rewardsDistribution;
    }
}

// Inheritance
contract OlympicStaking is
    IStakingRewards,
    RewardsDistributionRecipient,
    ReentrancyGuard,
    Pausable
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IERC20 public rewardsToken;
    IERC20 public stakingToken;
    uint256 public periodFinish = 0;

    uint256 public rewardRate = 0;
    uint256 public rewardETHRate = 0;

    uint256 public rewardsDuration = 90 days;
    uint256 public lockDuration = 7 days;
    uint256 public lastUpdateTime;

    uint256 public rewardPerTokenStored;
    uint256 public rewardPerETHStored;

    mapping(address => uint256) public userEntranceTime;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    mapping(address => uint256) public userRewardPerETHPaid;
    mapping(address => uint256) public rewardETH;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken
    ) {
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        rewardsDistribution = _rewardsDistribution;
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view override returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view override returns (uint256) {
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

    function rewardPerETH() public view returns (uint256) {
        uint256 totalBalance = address(this).balance;
        if (totalBalance == 0) {
            return rewardPerETHStored;
        }
        return
            rewardPerETHStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardETHRate)
                    .mul(1e18)
                    .div(totalBalance)
            );
    }

    function lockAddressDuration(address account)
        public
        view
        returns (uint256)
    {
        return block.timestamp.sub(userEntranceTime[account]);
    }

    function earned(address account) public view override returns (uint256) {
        return
            _balances[account]
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function earnedETH(address account) public view returns (uint256) {
        return
            _balances[account]
                .mul(rewardPerETH().sub(userRewardPerETHPaid[account]))
                .div(1e18)
                .add(rewardETH[account]);
    }

    function getRewardForDuration() external view override returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    function getETHRewardForDuration() external view returns (uint256) {
        return rewardETHRate.mul(rewardsDuration);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount)
        external
        override
        nonReentrant
        whenNotPaused
        updateReward(msg.sender)
    {
        require(amount > 0, "Cannot stake 0");
        userEntranceTime[msg.sender] = block.timestamp;
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount)
        public
        override
        nonReentrant
        updateReward(msg.sender)
    {
        require(amount > 0, "Cannot withdraw 0");
        require(lockAddressDuration(msg.sender) >= lockDuration, "Lock period");

        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public override nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        uint256 rewardInETH = rewardETH[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardETH[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            payable(msg.sender).transfer(rewardInETH);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() external override {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward)
        external
        payable
        onlyRewardsDistribution
        updateReward(address(0))
    {
        uint256 ethValue = msg.value;
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
            rewardETHRate = ethValue.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            uint256 leftoverETH = remaining.mul(rewardETHRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
            rewardETHRate = ethValue.add(leftoverETH).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = rewardsToken.balanceOf(address(this));
        require(
            rewardRate <= balance.div(rewardsDuration),
            "Provided reward too high"
        );

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(
            periodFinish == 0 || block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    receive() external payable {}

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        rewardPerETHStored = rewardPerETH();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            rewardETH[account] = earnedETH(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
            userRewardPerETHPaid[account] = rewardPerETHStored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);
}
