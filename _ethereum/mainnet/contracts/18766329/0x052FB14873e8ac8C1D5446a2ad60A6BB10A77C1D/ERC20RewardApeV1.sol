// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/* 
  ______                     ______                                 
 /      \                   /      \                                
|  ▓▓▓▓▓▓\ ______   ______ |  ▓▓▓▓▓▓\__   __   __  ______   ______  
| ▓▓__| ▓▓/      \ /      \| ▓▓___\▓▓  \ |  \ |  \|      \ /      \ 
| ▓▓    ▓▓  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\\▓▓    \| ▓▓ | ▓▓ | ▓▓ \▓▓▓▓▓▓\  ▓▓▓▓▓▓\
| ▓▓▓▓▓▓▓▓ ▓▓  | ▓▓ ▓▓    ▓▓_\▓▓▓▓▓▓\ ▓▓ | ▓▓ | ▓▓/      ▓▓ ▓▓  | ▓▓
| ▓▓  | ▓▓ ▓▓__/ ▓▓ ▓▓▓▓▓▓▓▓  \__| ▓▓ ▓▓_/ ▓▓_/ ▓▓  ▓▓▓▓▓▓▓ ▓▓__/ ▓▓
| ▓▓  | ▓▓ ▓▓    ▓▓\▓▓     \\▓▓    ▓▓\▓▓   ▓▓   ▓▓\▓▓    ▓▓ ▓▓    ▓▓
 \▓▓   \▓▓ ▓▓▓▓▓▓▓  \▓▓▓▓▓▓▓ \▓▓▓▓▓▓  \▓▓▓▓▓\▓▓▓▓  \▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓ 
         | ▓▓                                             | ▓▓      
         | ▓▓                                             | ▓▓      
          \▓▓                                              \▓▓         
 * App:             https://ApeSwap.finance
 * Medium:          https://ape-swap.medium.com
 * Twitter:         https://twitter.com/ape_swap
 * Telegram:        https://t.me/ape_swap
 * Announcements:   https://t.me/ape_swap_news
 * Discord:         https://discord.com/ApeSwap
 * Reddit:          https://reddit.com/r/ApeSwap
 * Instagram:       https://instagram.com/ApeSwap.finance
 * GitHub:          https://github.com/ApeSwapFinance
 */

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Initializable.sol";
import "./ReentrancyGuard.sol";

contract ERC20RewardApeV1 is ReentrancyGuard, Ownable, Initializable {
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. Rewards to distribute per second.
        uint256 lastRewardTime; // Last timestamp that Rewards distribution occurs.
        uint256 accRewardTokenPerShare; // Accumulated Rewards per share, times 1e30. See below.
    }

    // The stake token
    IERC20 public STAKE_TOKEN;
    // The reward token
    IERC20 public REWARD_TOKEN;

    // Is native token reward
    bool public isNativeTokenReward;

    // Reward tokens created per second.
    uint256 public rewardPerSecond;

    // Keep track of number of tokens staked in case the contract earns reflect fees
    uint256 public totalStaked = 0;
    // Keep track of number of reward tokens paid to find remaining reward balance
    uint256 public totalRewardsPaid = 0;
    // Keep track of number of reward tokens paid to find remaining reward balance
    uint256 public totalRewardsAllocated = 0;

    // Info of each pool.
    PoolInfo public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(address => UserInfo) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 private totalAllocPoint = 0;
    // The timestamp number when Reward mining starts.
    uint256 public startTime;
    // The timestamp number when mining ends.
    uint256 public bonusEndTime;

    event Deposit(address indexed sender, address indexed user, uint256 amount);
    event DepositRewards(uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event SkimStakeTokenFees(address indexed user, uint256 amount);
    event LogUpdatePool(uint256 bonusEndTime, uint256 rewardPerSecond);
    event EmergencyRewardWithdraw(address indexed user, uint256 amount);
    event EmergencySweepWithdraw(
        address indexed user,
        IERC20 indexed token,
        uint256 amount
    );

    function initialize(
        IERC20 _stakeToken,
        IERC20 _rewardToken,
        uint256 _rewardPerSecond,
        uint256 _startTime,
        uint256 _bonusEndTime
    ) external initializer {
        if (address(_rewardToken) == address(0)) {
            isNativeTokenReward = true;
        }
        STAKE_TOKEN = _stakeToken;
        REWARD_TOKEN = _rewardToken;
        rewardPerSecond = _rewardPerSecond;
        startTime = _startTime;
        bonusEndTime = _bonusEndTime;

        // staking pool
        poolInfo = PoolInfo({
            lpToken: _stakeToken,
            allocPoint: 1000,
            lastRewardTime: startTime,
            accRewardTokenPerShare: 0
        });

        totalAllocPoint = 1000;
    }

    // Return reward multiplier over the given _from to _to timestamp.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (_to <= bonusEndTime) {
            return _to - _from;
        } else if (_from >= bonusEndTime) {
            return 0;
        } else {
            return bonusEndTime - _from;
        }
    }

    /// @param  _bonusEndTime The timestamp when rewards will end
    function setBonusEndTime(uint256 _bonusEndTime) external onlyOwner {
        require(
            _bonusEndTime > block.timestamp,
            "new bonus end timestamp must be greater than current"
        );
        bonusEndTime = _bonusEndTime;
        emit LogUpdatePool(bonusEndTime, rewardPerSecond);
    }

    // View function to see pending Reward on frontend.
    function pendingReward(address _user)
        external
        view
        returns (uint256 pending)
    {
        UserInfo storage user = userInfo[_user];
        uint256 accRewardTokenPerShare = poolInfo.accRewardTokenPerShare;
        if (block.timestamp > poolInfo.lastRewardTime && totalStaked != 0) {
            uint256 multiplier = getMultiplier(
                poolInfo.lastRewardTime,
                block.timestamp
            );
            uint256 tokenReward = (multiplier *
                rewardPerSecond *
                poolInfo.allocPoint) / totalAllocPoint;
            accRewardTokenPerShare =
                accRewardTokenPerShare +
                ((tokenReward * 1e30) / totalStaked);
        }
        pending =
            (user.amount * accRewardTokenPerShare) /
            1e30 -
            user.rewardDebt;
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool() public {
        if (block.timestamp <= poolInfo.lastRewardTime) {
            return;
        }
        if (totalStaked == 0) {
            poolInfo.lastRewardTime = block.timestamp;
            return;
        }
        uint256 multiplier = getMultiplier(
            poolInfo.lastRewardTime,
            block.timestamp
        );
        uint256 tokenReward = (multiplier *
            rewardPerSecond *
            poolInfo.allocPoint) / totalAllocPoint;
        totalRewardsAllocated += tokenReward;
        poolInfo.accRewardTokenPerShare =
            poolInfo.accRewardTokenPerShare +
            ((tokenReward * 1e30) / totalStaked);
        poolInfo.lastRewardTime = block.timestamp;
    }

    /// Deposit staking token into the contract to earn rewards.
    /// @dev Since this contract needs to be supplied with rewards we are
    ///  sending the balance of the contract if the pending rewards are higher
    /// @param _amount The amount of staking tokens to deposit
    function deposit(uint256 _amount) external nonReentrant {
        _depositTo(_amount, msg.sender);
    }

    function depositTo(uint256 _amount, address _user) external nonReentrant {
        require(_user != address(0), "Can't deposit for null address");
        _depositTo(_amount, _user);
    }

    function _depositTo(uint256 _amount, address _user) internal {
        UserInfo storage user = userInfo[_user];
        updatePool();
        if (user.amount > 0) {
            uint256 pending = (user.amount * poolInfo.accRewardTokenPerShare) /
                1e30 -
                user.rewardDebt;
            if (pending > 0) {
                // If rewardBalance is low then revert to avoid losing the user's rewards
                require(
                    rewardBalance() >= pending,
                    "insufficient reward balance"
                );
                safeTransferRewardInternal(_user, pending, true);
            }
        }

        uint256 finalDepositAmount = 0;
        if (_amount > 0) {
            uint256 preStakeBalance = STAKE_TOKEN.balanceOf(address(this));
            poolInfo.lpToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            finalDepositAmount =
                STAKE_TOKEN.balanceOf(address(this)) -
                preStakeBalance;
            user.amount = user.amount + finalDepositAmount;
            totalStaked = totalStaked + finalDepositAmount;
        }
        user.rewardDebt =
            (user.amount * poolInfo.accRewardTokenPerShare) /
            1e30;

        emit Deposit(msg.sender, _user, finalDepositAmount);
    }

    /// Withdraw rewards and/or staked tokens. Pass a 0 amount to withdraw only rewards
    /// @param _amount The amount of staking tokens to withdraw
    function withdraw(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool();
        uint256 pending = (user.amount * poolInfo.accRewardTokenPerShare) /
            1e30 -
            user.rewardDebt;
        if (pending > 0) {
            // If rewardBalance is low then revert to avoid losing the user's rewards
            require(rewardBalance() >= pending, "insufficient reward balance");
            safeTransferRewardInternal(address(msg.sender), pending, true);
        }

        if (_amount > 0) {
            user.amount = user.amount - _amount;
            poolInfo.lpToken.safeTransfer(address(msg.sender), _amount);
            totalStaked = totalStaked - _amount;
        }

        user.rewardDebt =
            (user.amount * poolInfo.accRewardTokenPerShare) /
            1e30;

        emit Withdraw(msg.sender, _amount);
    }

    /// Obtain the reward balance of this contract
    /// @return wei balance of contract
    function rewardBalance() public view returns (uint256) {
        if (isNativeTokenReward) {
            return address(this).balance;
        } else {
            // Return ERC20 balance
            uint256 balance = REWARD_TOKEN.balanceOf(address(this));
            if (STAKE_TOKEN == REWARD_TOKEN) {
                return balance - totalStaked;
            }
            return balance;
        }
    }

    /// Get the balance of rewards that have not been harvested
    /// @return wei balance of rewards left to be paid
    function getUnharvestedRewards() public view returns (uint256) {
        return totalRewardsAllocated - totalRewardsPaid;
    }

    // Deposit Rewards into contract
    function depositRewards(uint256 _amount) external {
        require(!isNativeTokenReward, "Reward is native token");
        require(_amount > 0, "Deposit value must be greater than 0.");
        REWARD_TOKEN.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        emit DepositRewards(_amount);
    }

    /// @param _to address to send reward token to
    /// @param _amount value of reward token to transfer
    function safeTransferRewardInternal(
        address _to,
        uint256 _amount,
        bool _sumRewards
    ) internal {
        require(_amount <= rewardBalance(), "not enough reward token");
        if (_sumRewards) {
            totalRewardsPaid += _amount;
        }

        if (isNativeTokenReward) {
            // Transfer native token to address
            (bool success, ) = _to.call{gas: 23000, value: _amount}("");
            require(success, "TransferHelper: NATIVE_TRANSFER_FAILED");
        } else {
            // Transfer ERC20 to address
            REWARD_TOKEN.safeTransfer(_to, _amount);
        }
    }

    /// @dev Obtain the stake balance of this contract
    function totalStakeTokenBalance() public view returns (uint256) {
        if (STAKE_TOKEN == REWARD_TOKEN) return totalStaked;
        return STAKE_TOKEN.balanceOf(address(this));
    }

    /// @dev Obtain the stake token fees (if any) earned by reflect token
    /// @notice If STAKE_TOKEN == REWARD_TOKEN there are no fees to skim
    function getStakeTokenFeeBalance() public view returns (uint256) {
        return totalStakeTokenBalance() - totalStaked;
    }

    /* Admin Functions */

    /// @param _rewardPerSecond The amount of reward tokens to be given per second
    function setRewardPerSecond(uint256 _rewardPerSecond) external onlyOwner {
        rewardPerSecond = _rewardPerSecond;
        emit LogUpdatePool(bonusEndTime, rewardPerSecond);
    }

    /// @dev Remove excess stake tokens earned by reflect fees
    function skimStakeTokenFees(address _to) external onlyOwner {
        uint256 stakeTokenFeeBalance = getStakeTokenFeeBalance();
        STAKE_TOKEN.safeTransfer(_to, stakeTokenFeeBalance);
        emit SkimStakeTokenFees(_to, stakeTokenFeeBalance);
    }

    /* Emergency Functions */

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        poolInfo.lpToken.safeTransfer(address(msg.sender), user.amount);
        totalStaked = totalStaked - user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        emit EmergencyWithdraw(msg.sender, user.amount);
    }

    // Withdraw reward. EMERGENCY ONLY.
    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        // Withdraw rewards
        safeTransferRewardInternal(msg.sender, _amount, false);
        emit EmergencyRewardWithdraw(msg.sender, _amount);
    }

    /// @notice A public function to sweep accidental BEP20 transfers to this contract.
    ///   Tokens are sent to owner
    /// @param token The address of the BEP20 token to sweep
    function sweepToken(IERC20 token) external onlyOwner {
        require(
            address(token) != address(STAKE_TOKEN),
            "can not sweep stake token"
        );
        require(
            address(token) != address(REWARD_TOKEN),
            "can not sweep reward token"
        );
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(msg.sender, balance);
        emit EmergencySweepWithdraw(msg.sender, token, balance);
    }

    receive() external payable {
        if (!isNativeTokenReward) {
            revert("Reward token is not native");
        }
    }
}
