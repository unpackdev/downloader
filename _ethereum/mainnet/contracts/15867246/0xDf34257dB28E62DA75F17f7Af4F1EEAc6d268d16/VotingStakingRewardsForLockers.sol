// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./AccessControl.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./Math.sol";

import "./IVeToken.sol";
import "./IBoostLogicProvider.sol";

contract VotingStakingRewardsForLockers is
    Ownable,
    Pausable,
    ReentrancyGuard,
    AccessControl
{
    using SafeERC20 for IERC20;

    bytes32 public constant REGISTRATOR_ROLE = keccak256("REGISTRATOR_ROLE");

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount, uint256 boost);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    struct BondedReward {
        uint256 amount;
        uint256 unlockTime;
    }

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    mapping(address => uint256) internal _balances;

    uint256 public constant PCT_BASE = 10**18; // 0% = 0; 1% = 10^16; 100% = 10^18
    uint256 internal constant MAX_BOOST_LEVEL = PCT_BASE;
    IERC20 public rewardsToken;
    IERC20 public stakingToken;
    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public rewardsDuration;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    address public rewardsDistribution;

    uint256 public totalSupply;

    uint256 public percentageToBeLocked;

    IVeToken public veToken;
    IBoostLogicProvider public bonusCampaign;

    modifier onlyRegistrator() {    
        require(hasRole(REGISTRATOR_ROLE, msg.sender), "!registrator");
        _;
    }

    modifier onlyRewardsDistributionOrOwner() {
        require(
            msg.sender == rewardsDistribution ||
            msg.sender == owner(),
            "Caller is not RewardsDistribution contract nor owner"
        );
        _;
    }

    constructor(
        address _rewardsDistribution,
        IERC20 _rewardsToken,
        IERC20 _stakingToken,
        uint256 _rewardsDuration,
        IBoostLogicProvider _bonusCampaign,
        uint256 _percentageToBeLocked
    ) {
        rewardsToken = _rewardsToken;
        stakingToken = _stakingToken;
        rewardsDistribution = _rewardsDistribution;
        rewardsDuration = _rewardsDuration;
        bonusCampaign = _bonusCampaign;
        require(_percentageToBeLocked <= 100, "incorrect percentage");
        percentageToBeLocked = _percentageToBeLocked;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        uint256 _lastTimeReward = lastTimeRewardApplicable();
        uint256 _duration = _lastTimeReward - lastUpdateTime;
        rewardPerTokenStored = _rewardPerToken(_duration);
        lastUpdateTime = _lastTimeReward;
        if (account != address(0)) {
            uint256 userEarned = potentialTokenReturns(
                0,
                account
            );
            rewards[account] = userEarned;
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    

    /* ========== OWNERS FUNCTIONS ========== */

    function setPercentageToBeLocked(uint256 _percentageToBeLocked)
        external
        onlyOwner
    {
        require(_percentageToBeLocked <= 100, "incorrect percentage");
        percentageToBeLocked = _percentageToBeLocked;
    }

    function setRewardsDistribution(address _rewardsDistribution)
        external
        onlyOwner
    {
        rewardsDistribution = _rewardsDistribution;
    }

    function setBoostLogicProvider(address _bonusCampaign)
        external
        onlyOwner
    {
        bonusCampaign = IBoostLogicProvider(_bonusCampaign);
    }

    function setVeToken(address _newVeToken)
        external
        onlyOwner
    {
        veToken = IVeToken(_newVeToken);
        stakingToken.approve(address(veToken), type(uint256).max);
    }


    /* ========== VIEWS ========== */

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() external view returns (uint256) {
        return _rewardPerToken(lastTimeRewardApplicable() - lastUpdateTime);
    }

    function _rewardPerToken(uint256 duration) internal view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored + duration * rewardRate * PCT_BASE / totalSupply;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward)
        external
        onlyRewardsDistributionOrOwner
        updateReward(address(0))
    {
        uint256 rewardsDuration_ = rewardsDuration;
        if (block.timestamp >= periodFinish) {
            rewardRate = reward / rewardsDuration_;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (reward + leftover) / rewardsDuration_;
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = rewardsToken.balanceOf(address(this));
        require(
            rewardRate <= balance / rewardsDuration_,
            "Provided reward too high"
        );

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardsDuration_;
        emit RewardAdded(reward);
    }

    function processLockEvent(
        address _account,
        uint256 _lockStart,
        uint256 _lockEnd,
        uint256 _amount
    ) external onlyRegistrator updateReward(_account) {
        uint256 currentBoost = calculateBoostLevel(_account);
        uint256 currentBoostedAmount = _amount * currentBoost / PCT_BASE;

        totalSupply = totalSupply + currentBoostedAmount;
        _balances[_account] = _balances[_account] + currentBoostedAmount;

        emit Staked(_account, _amount, currentBoost);

    }

    function processWitdrawEvent(
        address _account,
        uint256 _amount
    ) external onlyRegistrator updateReward(_account) {

        totalSupply = totalSupply - _balances[_account];
        delete _balances[_account];

        emit Withdrawn(_account, _amount);

    }

    function calculateBoostLevel(address account)
        public
        view
        returns (uint256)
    {
        uint256 base = PCT_BASE;
        uint256 maxBoost = 25 * base / 10;
        if (bonusCampaign.hasMaxBoostLevel(account)) return maxBoost;

        IVeToken veToken_ = veToken;
        uint256 votingBalance = veToken_.balanceOf(account);
        uint256 lockedAmount = veToken_.lockedAmount(account);
        uint256 tokenBalance = IERC20(rewardsToken).balanceOf(account);

        if (votingBalance == 0) return base;
        uint256 boost = base + 15 * base * votingBalance / (10 * (tokenBalance + lockedAmount));

        if (boost < base) { // just in case
            boost = base;
        } else if (boost > maxBoost) {
            boost = maxBoost;
        }

        return boost;
    } 


    function earned(address account)
        external
        view
        returns (
            uint256 // userEarned
        )
    {
        uint256 duration = lastTimeRewardApplicable() - lastUpdateTime;
        uint256 userEarned = potentialTokenReturns(duration, account);
        return userEarned;
    }

    function potentialTokenReturns(uint256 duration, address account)
        public
        view
        returns (uint256)
    {
        uint256 pendingReward = _balances[account] * (_rewardPerToken(duration) - userRewardPerTokenPaid[account]) / PCT_BASE;
        uint256 toUser = pendingReward;
        return toUser + rewards[account];
    }

    function getReward() external nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            _transferOrLock(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function _transferOrLock(address _account, uint256 _amount) internal {
        uint256 toLock = percentageToBeLocked * _amount / 100;
        uint256 toTransfer = _amount - toLock;
        IVeToken veToken_ = veToken;
        uint256 unlockTime = veToken_.lockedEnd(_account);
        if (unlockTime == 0) {
            IVeToken.Point memory initialPoint = veToken_.pointHistory(0);
            uint256 lockTime = veToken_.MAXTIME();
            uint256 week = veToken_.WEEK();
            if (initialPoint.ts + lockTime + rewardsDuration < block.timestamp) { // reward program is surely over
                rewardsToken.safeTransfer(_account, _amount);
            } else {
                rewardsToken.safeTransfer(_account, toTransfer);
                uint256 unlockDate = 
                        (initialPoint.ts + lockTime) / week * week <= block.timestamp ? // if we are between 100 and 101 week
                        block.timestamp + 2 * rewardsDuration : 
                        initialPoint.ts + lockTime;
                veToken_.createLockFor(_account, toLock, unlockDate);
            }

        } else {
            require(unlockTime > block.timestamp, "withdraw the lock first");
            rewardsToken.safeTransfer(_account, toTransfer);
            veToken_.increaseAmountFor(_account, toLock);
        }
    }
}
