// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";


/** @title Staking
 * @notice Manual Staking Contract for Ariva
 */

contract Staking is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 pendingRewards;
        uint256 lastAction;
    }

    struct PoolInfo {
        uint256 lastRewardBlock;
        uint256 accTokenPerShare;
        uint256 depositedAmount;
        uint256 rewardsAmount;
        uint256 lockupDuration; // 3 days;
    }

    IERC20 public token;
    uint256 public tokenPerBlock;

    PoolInfo public poolInfo;
    mapping(address => UserInfo) public userInfo;

    // this is necessary to whitelist auto-compound pool and exclude it from fee
    mapping(address => bool) public isWhitelistedFromFee;

    // normally 1% fee when withdraw
    uint256 public withdrawFee;
    // 5% fee when users withdraw within 3 days
    uint256 public emergencyWithdrawFee;
    uint256 public constant FEE_MULTIPLIER = 10000;

    uint256 public constant SHARE_MULTIPLIER = 1e12;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);
    event RewardPerBlockChanged(uint256 reward);
    event TokenAddressSet(address token);
    event StakingStarted(uint256 startBlock);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event Pause();
    event Unpause();

    function initialize(IERC20 _token, uint256 lockupDuration) public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();

        require(address(token) == address(0), "Token already set!");
        require(address(_token) != address(0), "Invalid Token Address");
        require(lockupDuration > 0, "Invalid lockupDuration");

        token = _token;
        poolInfo.lockupDuration = lockupDuration;

        withdrawFee = 100; // 1%
        emergencyWithdrawFee = 500; // 5%
        tokenPerBlock = 1 ether; // default

        emit TokenAddressSet(address(token));
    }

    /**
     * @notice get Pending Rewards of a user
     *
     * @param _user: User Address
     */
    function pendingRewards(address _user) external view returns (uint256) {
        require(_user != address(0), "Invalid user address");
        require(poolInfo.lastRewardBlock > 0, "Staking not yet started");
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[_user];
        uint256 accTokenPerShare = pool.accTokenPerShare;
        uint256 depositedAmount = pool.depositedAmount;
        if (block.number > pool.lastRewardBlock && depositedAmount != 0) {
            uint256 multiplier = block.number - (pool.lastRewardBlock);
            uint256 tokenReward = multiplier * tokenPerBlock;
            accTokenPerShare = accTokenPerShare + ((tokenReward * SHARE_MULTIPLIER) / depositedAmount);
        }
        return (user.amount * accTokenPerShare) / SHARE_MULTIPLIER - user.rewardDebt + user.pendingRewards;
    }

    /**
     * @notice updatePool distribute pendingRewards
     */
    function updatePool() internal {
        require(poolInfo.lastRewardBlock > 0, "Staking not yet started");
        PoolInfo storage pool = poolInfo;
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 depositedAmount = pool.depositedAmount;
        if (pool.depositedAmount == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = block.number - pool.lastRewardBlock;
        uint256 tokenReward = multiplier * tokenPerBlock;
        pool.rewardsAmount = pool.rewardsAmount + tokenReward;
        pool.accTokenPerShare = pool.accTokenPerShare + ((tokenReward * SHARE_MULTIPLIER) / depositedAmount);
        pool.lastRewardBlock = block.number;
    }

    function processRewards(address addr) internal {
        UserInfo storage user = userInfo[addr];

        uint256 pending = (user.amount * (poolInfo.accTokenPerShare)) / SHARE_MULTIPLIER - user.rewardDebt;
        if (pending > 0) {
            user.pendingRewards += pending;

            uint256 claimedAmount = safeTokenTransfer(addr, user.pendingRewards);
            emit Claim(addr, claimedAmount);
            user.pendingRewards -= claimedAmount;

            poolInfo.rewardsAmount -= claimedAmount;
        }
    }

    /**
     * @notice deposit token
     *
     * @param amount: Amount of token to deposit
     */
    function deposit(uint256 amount) external nonReentrant whenNotPaused {
        UserInfo storage user = userInfo[msg.sender];

        updatePool();

        if (user.amount > 0) {
            processRewards(msg.sender);
        }

        if (amount > 0) {
            token.safeTransferFrom(address(msg.sender), address(this), amount);
            user.amount = user.amount + amount;
            poolInfo.depositedAmount = poolInfo.depositedAmount + amount;

            user.lastAction = block.timestamp;

            emit Deposit(msg.sender, amount);
        }
        user.rewardDebt = (user.amount * (poolInfo.accTokenPerShare)) / (SHARE_MULTIPLIER);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() external nonReentrant whenNotPaused {
        UserInfo storage user = userInfo[msg.sender];

        updatePool();
        uint256 pending = (user.amount * (poolInfo.accTokenPerShare)) / SHARE_MULTIPLIER - user.rewardDebt;
        if (pending > 0) {
            user.pendingRewards += pending;
        }

        uint256 amount = user.amount;
        uint256 feeAmount = (amount * withdrawFee) / FEE_MULTIPLIER;
        if (block.timestamp < user.lastAction + poolInfo.lockupDuration) {
            feeAmount = (amount * emergencyWithdrawFee) / FEE_MULTIPLIER;
        }
        if (isWhitelistedFromFee[msg.sender]) {
            feeAmount = 0;
        }

        poolInfo.rewardsAmount -= user.pendingRewards;
        poolInfo.depositedAmount -= amount;

        token.safeTransfer(msg.sender, user.amount - feeAmount);

        user.amount = 0;
        user.rewardDebt = 0;
        user.lastAction = block.timestamp;
        user.pendingRewards = 0;

        emit EmergencyWithdraw(msg.sender, amount);
    }

    /**
     * @notice withdraw token
     *
     * @param amount: Amount of token to withdraw
     */
    function withdraw(uint256 amount) external nonReentrant whenNotPaused {
        UserInfo storage user = userInfo[msg.sender];

        require(user.amount >= amount, "Withdrawing more than you have!");

        uint256 feeAmount = (amount * withdrawFee) / FEE_MULTIPLIER;
        if (block.timestamp < user.lastAction + poolInfo.lockupDuration) {
            feeAmount = (amount * emergencyWithdrawFee) / FEE_MULTIPLIER;
        }
        if (isWhitelistedFromFee[msg.sender]) {
            feeAmount = 0;
        }

        updatePool();

        if (user.amount > 0) {
            processRewards(msg.sender);
        }

        if (amount > 0) {
            token.safeTransfer(address(msg.sender), amount - feeAmount);
            user.amount -= amount;
            poolInfo.depositedAmount -= amount;

            user.lastAction = block.timestamp;
            emit Withdraw(msg.sender, amount);
        }
        user.rewardDebt = (user.amount * poolInfo.accTokenPerShare) / SHARE_MULTIPLIER;
    }

    function safeTokenTransfer(address to, uint256 amount) internal returns (uint256) {
        uint256 tokenBal = token.balanceOf(address(this));
        uint256 maxRewards = tokenBal - poolInfo.depositedAmount;

        if (amount > maxRewards) {
            token.safeTransfer(to, maxRewards);
            return maxRewards;
        } else {
            token.safeTransfer(to, amount);
            return amount;
        }
    }

    /**
     * @notice Withdraw unexpected tokens sent to the Staking
     */
    function withdrawAnyToken(IERC20 _token, uint256 amount) external onlyOwner {
        require(address(_token) != address(token), "Token cannot be same as deposit token");
        _token.safeTransfer(msg.sender, amount);
    }

    /**
     * @notice set startBlock of staking
     */
    function startStaking(uint256 startBlock) external onlyOwner {
        require(poolInfo.lastRewardBlock == 0, "Staking already started");
        poolInfo.lastRewardBlock = startBlock;
        emit StakingStarted(startBlock);
    }

    /**
     * @notice set token per block
     */
    function setTokenPerBlock(uint256 _tokenPerBlock) external onlyOwner {
        require(_tokenPerBlock > 0, "Token per block should be greater than 0!");
        tokenPerBlock = _tokenPerBlock;

        emit RewardPerBlockChanged(_tokenPerBlock);
    }

    /**
     * @notice set fee info
     */
    function setFeeInfo(uint256 _emergencyWithdrawFee, uint256 _withdrawFee) external onlyOwner {
        require(_emergencyWithdrawFee < FEE_MULTIPLIER, "Invalid emergencyWithdrawFee");
        require(_withdrawFee < _emergencyWithdrawFee, "Invalid withdrawFee");

        emergencyWithdrawFee = _emergencyWithdrawFee;
        withdrawFee = _withdrawFee;
    }

    /**
     * @notice exclude from fee (this function is for vault)
     */
    function excludeFromFee(address addr, bool isWhitelisted) external onlyOwner {
        isWhitelistedFromFee[addr] = isWhitelisted;
    }

    /**
     * @notice Triggers stopped state
     * @dev Only possible when contract not paused.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
        emit Pause();
    }

    /**
     * @notice Returns to normal state
     * @dev Only possible when contract is paused.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
        emit Unpause();
    }
}
