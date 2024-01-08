pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./TokenStaking.sol";

// https://docs.synthetix.io/contracts/source/contracts/stakingrewards
contract Staking is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    TokenStaking legacy;

    IERC20 public rewardsToken;
    IERC20 public stakingToken;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration = 30 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    uint256 public lockTime = 30 days;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    mapping(address => uint256) public stakeStart;
    mapping(address => bool) public migrated;
    uint256 constant MAX_WEIGHT = 3 * 10**19;
    uint256 public startingWeights;
    mapping(address => StakeAccount) public legacyStakeAccounts;

    uint256 public legacyCarry;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _rewardsToken,
        address _stakingToken,
        address legacyContract
    ) Ownable() {
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        legacy = TokenStaking(legacyContract);
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

    function viewRewardAmount(address account) public view returns (uint256) {
        return
            _balances[account]
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    function _rewardDiff(StakeAccount memory account)
        internal
        view
        returns (uint256)
    {
        uint256 totalReward = legacy.viewUpdatedCumulativeReward();

        uint256 startingReward =
            ((totalReward - account.cumulativeStart) * account.stakeWeight) /
                (startingWeights + 1);

        uint256 currentReward =
            ((totalReward - account.cumulativeStart) * account.stakeWeight) /
                (legacy.totalCurrentWeights() + 1);

        if (startingReward >= currentReward) {
            return 0;
        } else {
            return currentReward - startingReward;
        }
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount)
        external
        nonReentrant
        updateReward(msg.sender)
    {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
        if (stakeStart[msg.sender] == 0) {
            stakeStart[msg.sender] = block.timestamp;
        }
    }

    function withdrawStake(uint256 amount)
        external
        nonReentrant
        updateReward(msg.sender)
    {
        require(amount > 0, "Cannot withdraw 0");
        require(block.timestamp >= stakeStart[msg.sender] + lockTime);

        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);

        if (migrated[msg.sender]) {
            uint256 w;
            uint256 __;
            (__, w, __, __) = legacy.stakeAccounts(msg.sender);
            require(w < MAX_WEIGHT, "Migrate account first");

            uint256 rewardDiff = _rewardDiff(legacyStakeAccounts[msg.sender]);
            if (rewardDiff >= amount) {
                amount = 0;
            } else {
                amount -= rewardDiff;
            }
        }

        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function withdrawReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward)
        external
        onlyOwner
        updateReward(address(0))
    {
        if (legacyCarry > 0) {
            reward -= legacyCarry;
            legacyCarry = 0;
        }
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
        uint256 balance = rewardsToken.balanceOf(address(this));
        require(
            rewardRate <= balance.div(rewardsDuration),
            "Provided reward too high"
        );

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    // End rewards emission earlier
    function updatePeriodFinish(uint256 timestamp)
        external
        onlyOwner
        updateReward(address(0))
    {
        periodFinish = timestamp;
    }

    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        external
        onlyOwner
    {
        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    function setLockTime(uint256 t) external onlyOwner {
        lockTime = t;
    }

    function migrate(address[] calldata accounts) external onlyOwner {
        startingWeights = legacy.totalCurrentWeights();
        uint256 _startingWeights = startingWeights;
        uint256 _rewardTarget = legacy.rewardTarget();

        uint256 _legacyCarry;
        for (uint256 i; accounts.length > i; i++) {
            address accountAddress = accounts[i];
            StakeAccount memory account;
            (
                account.stakeAmount,
                account.stakeWeight,
                account.cumulativeStart,
                account.lockEnd
            ) = legacy.stakeAccounts(accountAddress);
            uint256 amount = account.stakeAmount;

            _totalSupply = _totalSupply.add(amount);
            _balances[accountAddress] = _balances[accountAddress].add(amount);
            stakeStart[accountAddress] = account.lockEnd - lockTime;
            migrated[accountAddress] = true;
            legacyStakeAccounts[accountAddress] = account;

            if (account.lockEnd > block.timestamp) {
                uint256 remaining = account.lockEnd - block.timestamp;
                if (remaining > 30 days) {
                    // bonus is the additional 1 / 3 of reward that a 3 month should get relative to standard
                    // 1 month lockup
                    // calculated for their remaining reward period
                    uint256 bonus =
                        (((_rewardTarget * account.stakeWeight) /
                            _startingWeights) * (90 days - remaining)) /
                            (90 days) /
                            3;
                    rewards[accountAddress] += bonus;
                    _legacyCarry += bonus;
                }
            }
            legacyCarry += _legacyCarry;
        }
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = viewRewardAmount(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
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
