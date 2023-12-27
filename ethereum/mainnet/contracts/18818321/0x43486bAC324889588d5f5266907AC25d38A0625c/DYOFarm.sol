// SPDX-License-Identifier: MIT

// DYOFarm:
// Create custom reward pools to incentivize stakers of any ERC20!
// https://twitter.com/DYOFarm
pragma solidity =0.7.6;
pragma abicoder v2;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./EnumerableSet.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

import "./DYOFarmFactory.sol";

contract DYOFarm is ReentrancyGuard, Ownable {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct UserInfo {
        uint256 totalDepositAmount; // Save total deposit amount
        uint256 rewardDebtToken1;
    }

    struct Settings {
        uint256 startTime; // Start of rewards distribution
        uint256 endTime; // End of rewards distribution
    }

    struct RewardsToken {
        IERC20 token;
        uint256 amount; // Total rewards to distribute
        uint256 remainingAmount; // Remaining rewards to distribute
        uint256 accRewardsPerShare;
    }

    IDYOFarmFactory public factory;
    uint256 public creationTime; // Creation time of this DYOFarm.sol
    bool public emergencyClose; // When activated, can't distribute rewards anymore

    IERC20 public depositToken;
    RewardsToken public rewardsToken1; // rewardsToken1 data

    // pool info
    uint256 public totalDepositAmount;
    uint256 public lastRewardTime;

    mapping(address => UserInfo) public userInfo;

    Settings public settings; // global and requirements settings

    constructor(address owner_, IERC20 depositToken_, IERC20 rewardsToken1_, Settings memory settings_) {
        require(_currentBlockTimestamp() < settings_.startTime, "invalid startTime");
        require(settings_.startTime < settings_.endTime, "invalid endTime");

        factory = IDYOFarmFactory(msg.sender);

        creationTime = _currentBlockTimestamp();

        depositToken = depositToken_;
        rewardsToken1.token = rewardsToken1_;

        settings.startTime = settings_.startTime;
        settings.endTime = settings_.endTime;
        lastRewardTime = settings_.startTime;

        Ownable.transferOwnership(owner_);
    }

    event ActivateEmergencyClose();
    event AddRewardsToken1(uint256 amount, uint256 feeAmount);
    event Deposit(address indexed userAddress, uint256 amount);
    event Harvest(address indexed userAddress, IERC20 rewardsToken, uint256 pending);
    event SetDateSettings(uint256 endTime);
    event UpdatePool();
    event Withdraw(address indexed userAddress, uint256 amount);
    event EmergencyWithdraw(address indexed userAddress, uint256 amount);
    event WithdrawRewardsToken1(uint256 amount, uint256 totalRewardsAmount);

    /**
     * @dev Returns the amount of rewardsToken1 distributed every second
     */
    function rewardsToken1PerSecond() public view returns (uint256) {
        if (settings.endTime <= lastRewardTime) return 0;
        return rewardsToken1.remainingAmount.div(settings.endTime.sub(lastRewardTime));
    }

    /**
     * @dev Returns pending rewards (rewardsToken1) for "account" address
     */
    function pendingRewards(address account) external view returns (uint256 pending1) {
        UserInfo memory user = userInfo[account];

        // recompute accRewardsPerShare for rewardsToken1 if not up to date
        uint256 accRewardsToken1PerShare_ = rewardsToken1.accRewardsPerShare;

        // only if existing deposits and lastRewardTime already passed
        if (lastRewardTime < _currentBlockTimestamp() && totalDepositAmount > 0) {
            uint256 rewardsAmount = rewardsToken1PerSecond().mul(_currentBlockTimestamp().sub(lastRewardTime));
            // in case of rounding errors
            if (rewardsAmount > rewardsToken1.remainingAmount) rewardsAmount = rewardsToken1.remainingAmount;
            accRewardsToken1PerShare_ = accRewardsToken1PerShare_.add(rewardsAmount.mul(1e18).div(totalDepositAmount));
        }
        pending1 = (user.totalDepositAmount.mul(accRewardsToken1PerShare_).div(1e18).sub(user.rewardDebtToken1));
    }

    /**
     * @dev Update this DYOFarm.sol
     */
    function updatePool() external nonReentrant {
        _updatePool();
    }

    function deposit(uint256 amount) external {
        require((settings.endTime >= _currentBlockTimestamp()) && !emergencyClose, "not allowed");
        uint256 balanceBefore = IERC20(depositToken).balanceOf(address(this));
        IERC20(depositToken).transferFrom(msg.sender, address(this), amount);
        _deposit(msg.sender, amount);
        require(balanceBefore + amount >= IERC20(depositToken).balanceOf(address(this)), "Likely a fee on transfer error");
    }

    function withdraw(uint256 amount) external virtual nonReentrant {
        _updatePool();
        UserInfo storage user = userInfo[msg.sender];
        require(user.totalDepositAmount >= amount, "Withdrawing too much");
        _harvest(user, msg.sender);

        user.totalDepositAmount = user.totalDepositAmount.sub(amount);
        totalDepositAmount = totalDepositAmount.sub(amount);

        _updateRewardDebt(user);

        IERC20(depositToken).transfer(msg.sender, amount);

        emit Withdraw(msg.sender, amount);
    }

    function emergencyWithdraw() external virtual nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        uint256 amount = user.totalDepositAmount;

        user.totalDepositAmount = user.totalDepositAmount.sub(amount);
        totalDepositAmount = totalDepositAmount.sub(amount);

        _updateRewardDebt(user);

        IERC20(depositToken).transfer(msg.sender, amount);

        emit EmergencyWithdraw(msg.sender, amount);
    }

    /**
     * @dev Harvest pending DYOFarm.sol rewards
     */
    function harvest() external nonReentrant {
        _updatePool();
        UserInfo storage user = userInfo[msg.sender];
        _harvest(user, msg.sender);
        _updateRewardDebt(user);
    }

    /**
     * @dev Transfer ownership of this DYOFarm.sol
     *
     * Must only be called by the owner of this contract
     */
    function transferOwnership(address newOwner) public override onlyOwner {
        _setNitroPoolOwner(newOwner);
        Ownable.transferOwnership(newOwner);
    }

    /**
     * @dev Transfer ownership of this DYOFarm.sol
     *
     * Must only be called by the owner of this contract
     */
    function renounceOwnership() public override onlyOwner {
        _setNitroPoolOwner(address(0));
        Ownable.renounceOwnership();
    }

    /**
     * @dev Add rewards to this DYOFarm.sol
     */
    function addRewards(uint256 amountToken1) external nonReentrant {
        require(_currentBlockTimestamp() < settings.endTime, "pool ended");
        _updatePool();

        // get active fee share for this DYOFarm.sol
        uint256 feeShare = factory.getNitroPoolFee(address(this), owner());
        address feeAddress = factory.feeAddress();
        uint256 feeAmount;

        if (amountToken1 > 0) {
            // token1 fee
            feeAmount = amountToken1.mul(feeShare).div(10000);
            amountToken1 =
                _transferSupportingFeeOnTransfer(rewardsToken1.token, msg.sender, amountToken1.sub(feeAmount));

            // recomputes rewards to distribute
            rewardsToken1.amount = rewardsToken1.amount.add(amountToken1);
            rewardsToken1.remainingAmount = rewardsToken1.remainingAmount.add(amountToken1);

            emit AddRewardsToken1(amountToken1, feeAmount);

            if (feeAmount > 0) {
                rewardsToken1.token.safeTransferFrom(msg.sender, feeAddress, feeAmount);
            }
        }
    }

    /**
     * @dev Withdraw rewards from this DYOFarm.sol
     *
     * Must only be called by the owner
     * Must only be called before the start time of the Nitro Pool
     */
    function withdrawRewards(uint256 amountToken1) external onlyOwner nonReentrant {
        require(block.timestamp < settings.startTime);
        if (amountToken1 > 0) {
            // recomputes rewards to distribute
            rewardsToken1.amount = rewardsToken1.amount.sub(amountToken1, "too high");
            rewardsToken1.remainingAmount = rewardsToken1.remainingAmount.sub(amountToken1, "too high");

            emit WithdrawRewardsToken1(amountToken1, rewardsToken1.amount);
            _safeRewardsTransfer(rewardsToken1.token, msg.sender, amountToken1);
        }
    }

    /**
     * @dev Set the pool's datetime settings
     *
     * Must only be called by the owner
     */
    function setDateSettings(uint256 endTime_) external nonReentrant onlyOwner {
        require(settings.startTime < endTime_, "invalid endTime");
        require(_currentBlockTimestamp() <= settings.endTime, "pool ended");

        settings.endTime = endTime_;

        emit SetDateSettings(endTime_);
    }

    /**
     * @dev Emergency close
     *
     * Must only be called by the owner
     * Emergency only: if used, the whole pool is definitely made void
     * All rewards are automatically transferred to the emergency recovery address
     */
    function activateEmergencyClose() external nonReentrant onlyOwner {
        address emergencyRecoveryAddress = factory.emergencyRecoveryAddress();

        uint256 remainingToken1 = rewardsToken1.remainingAmount;

        rewardsToken1.amount = rewardsToken1.amount.sub(remainingToken1);
        rewardsToken1.remainingAmount = 0;

        emergencyClose = true;

        emit ActivateEmergencyClose();
        // transfer rewardsToken1 remaining amount if any
        _safeRewardsTransfer(rewardsToken1.token, emergencyRecoveryAddress, remainingToken1);
    }

    /**
     * @dev Updates rewards states of this Nitro Pool to be up-to-date
     */
    function _updatePool() internal {
        uint256 currentBlockTimestamp = _currentBlockTimestamp();

        if (currentBlockTimestamp <= lastRewardTime) return;

        // do nothing if there is no deposit
        if (totalDepositAmount == 0) {
            lastRewardTime = currentBlockTimestamp;
            emit UpdatePool();
            return;
        }

        // updates rewardsToken1 state
        uint256 rewardsAmount = rewardsToken1PerSecond().mul(currentBlockTimestamp.sub(lastRewardTime));
        // ensure we do not distribute more than what's available
        if (rewardsAmount > rewardsToken1.remainingAmount) rewardsAmount = rewardsToken1.remainingAmount;
        rewardsToken1.remainingAmount = rewardsToken1.remainingAmount.sub(rewardsAmount);
        rewardsToken1.accRewardsPerShare =
            rewardsToken1.accRewardsPerShare.add(rewardsAmount.mul(1e18).div(totalDepositAmount));

        lastRewardTime = currentBlockTimestamp;
        emit UpdatePool();
    }

    /**
     * @dev Add a user's deposited amount into this Nitro Pool
     */
    function _deposit(address account, uint256 amount) internal {
        _updatePool();

        UserInfo storage user = userInfo[account];
        _harvest(user, account);

        user.totalDepositAmount = user.totalDepositAmount.add(amount);
        totalDepositAmount = totalDepositAmount.add(amount);
        _updateRewardDebt(user);

        emit Deposit(account, amount);
    }

    /**
     * @dev Transfer to a user its pending rewards
     */
    function _harvest(UserInfo storage user, address to) internal {
        uint256 pending =
            user.totalDepositAmount.mul(rewardsToken1.accRewardsPerShare).div(1e18).sub(user.rewardDebtToken1);
        _safeRewardsTransfer(rewardsToken1.token, to, pending);

        emit Harvest(to, rewardsToken1.token, pending);
    }

    /**
     * @dev Update a user's rewardDebt for rewardsToken1
     */
    function _updateRewardDebt(UserInfo storage user) internal virtual {
        (bool succeed, uint256 result) = user.totalDepositAmount.tryMul(rewardsToken1.accRewardsPerShare);
        if (succeed) user.rewardDebtToken1 = result.div(1e18);
    }

    /**
     * @dev Handle deposits of tokens with transfer tax
     */
    function _transferSupportingFeeOnTransfer(IERC20 token, address user, uint256 amount)
        internal
        returns (uint256 receivedAmount)
    {
        uint256 previousBalance = token.balanceOf(address(this));
        token.safeTransferFrom(user, address(this), amount);
        return token.balanceOf(address(this)).sub(previousBalance);
    }

    /**
     * @dev Safe token transfer function, in case rounding error causes pool to not have enough tokens
     */
    function _safeRewardsTransfer(IERC20 token, address to, uint256 amount) internal virtual {
        if (amount == 0) return;

        uint256 balance = token.balanceOf(address(this));
        // cap to available balance
        if (amount > balance) {
            amount = balance;
        }
        token.safeTransfer(to, amount);
    }

    function _setNitroPoolOwner(address newOwner) internal {
        factory.setNitroPoolOwner(owner(), newOwner);
    }

    /**
     * @dev Utility function to get the current block timestamp
     */
    function _currentBlockTimestamp() internal view virtual returns (uint256) {
        /* solhint-disable not-rely-on-time */
        return block.timestamp;
    }
}
