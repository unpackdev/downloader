// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./Ownable.sol";
import "./Ownable2Step.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./StakingPoolWithCoolOff.sol";
import "./StakingPoolWithLock.sol";

error EthTransferFailed();
error AmountIsZero();
error NoTokensToWithdraw(address erc20address);
error ActionDisabled();
error NewStakeNotHigherThanCurrent();

struct StakingPoolConfig {
    address goodTokenAddress;
    address owner;
    uint256 coolOffPeriod;
    uint256 stakingLockPeriod;
    uint256 vipMembershipThreshold;
}

/**
 * @dev This contract allows staking of ERC20 tokens and rewards stakers with ETH. The contract address
 * must be whitelisted/exempt from GOOD token transfer fees for proper functionality. When new rewards (ETH)
 * are deposited to the contract, every staker receives a proportional share of the rewards based on the
 * amount of tokens staked. The contract records historical deposits of rewards and uses them to calculate
 * user rewards during withdrawal. Users can withdraw their rewards at any time.
 *
 * When rewards are received, the contract calculates the proportional value of incoming rewards per staked
 * token and stores it in the `rewardsPerToken` array. The array is a prefix sum array, enabling the
 * constant-time calculation of the sum of rewards per token by subtracting the value at the staking time
 * (rewardsStartIndex) from the last value in the array. The total reward for staking is then determined
 * by multiplying the sum of rewards per token by the amount of staked tokens.
 *
 * The contract provides two types of staking: staking with a cool-off period and staking with a lock
 * period. Staking with a cool-off period allows users to unstake their tokens at any time, initiating
 * the `coolOffPeriod` (default of 48 hours), after which the user can transfer the tokens back to their
 * wallet. Staking with a lock period restricts users from withdrawing their staked tokens for a specified
 * period (stakingLockPeriod) after staking. Once this period concludes, the user can immediately withdraw
 * the tokens at any time. Staking with a lock period also allows users to become VIP members if their
 * locked amount exceeds the VIP membership threshold. These users can mint the VIP Membership NFT for free,
 * instead of paying the VIP membership fee. From a rewards perspective, both types of staking are treated
 * the same way; the calculated share of rewards is uniform regardless of the staking type and depends
 * solely on the amount of staked tokens.
 *
 * The contract is divided into multiple files for readability. The main contract is `StakingPool`,
 * responsible for reward calculation and withdrawals, ERC20 token transfers and contract parameters updates.
 * The internal logic of the two staking types is abstracted into two contracts (`StakingPoolWithCoolOff` and
 * `StakingPoolWithLock`), which `StakingPool` inherits from.
 */
contract StakingPool is Ownable2Step, StakingPoolWithCoolOff, StakingPoolWithLock {
    using SafeERC20 for IERC20;

    /**
     * @dev Arbitrary unit of reward calculation precision.
     * Calculated reward per token is an integer value, so if staked amount would be higher than that, we would
     * lose precision for last digits. Therefore we calculate the rewards per {{PRECISION}} tokens instead.
     * Value of 10x the total supply of GOOD token is chosen, so that the staked amounts are always lower than that.
     */
    uint256 internal constant PRECISION = 1e9 * 1e10;

    address public immutable goodTokenAddress;
    uint256 public undistributedRewards;
    uint256 public totalStakedAmount;
    uint256 public totalUnstakedTokens;
    uint256 public totalDepositedRewards;

    mapping(address => uint256) internal userBalances;

    uint256[] internal rewardsPerToken = [0];

    event RewardsDeposit(uint256 amount);
    event RewardsWithdrawal(address indexed user, uint256 amount);
    event OwnerERC20Withdrawal(address indexed user, address indexed erc20address, uint256 amount);

    constructor(StakingPoolConfig memory config)
        Ownable(config.owner)
        StakingPoolWithCoolOff(config.coolOffPeriod)
        StakingPoolWithLock(config.stakingLockPeriod, config.vipMembershipThreshold)
    {
        goodTokenAddress = config.goodTokenAddress;
    }

    receive() external payable {
        depositStakingRewards();
    }

    /**
     * @dev Explicit function to deposit ETH rewards.
     * If no tokens are staked, the rewards are accumulated in the `undistributedRewards` variable.
     * Otherwise the incoming rewards together with any `undistributedRewards` are "allocated" among stakers.
     * This is done by calculating the rewards per staked token and storing it in the `rewardsPerToken`
     * prefix sum array.
     */
    function depositStakingRewards() public payable {
        emit RewardsDeposit(msg.value);

        totalDepositedRewards += msg.value;

        if (totalStakedAmount == 0) {
            undistributedRewards += msg.value;
            return;
        }

        uint256 totalRewardAmount = msg.value + undistributedRewards;
        undistributedRewards = 0;
        uint256 rewardPerToken = (totalRewardAmount * PRECISION) / totalStakedAmount;

        rewardsPerToken.push(rewardsPerToken[_getLastRewardsIndex()] + rewardPerToken);
    }

    /**
     * @dev Function from Ownable to renounce ownership of the contract. Overriden to disable this function.
     */
    function renounceOwnership() public pure override(Ownable) {
        revert ActionDisabled();
    }

    /**
     * @dev Getter for current value of staking rewards for a given user.
     */
    function getCurrentRewards(address user) public view returns (uint256) {
        return userBalances[user] + _calculateStakingRewards(userStakingsWithCoolOff[user])
            + _calculateStakingRewards(userStakingsWithLock[user]);
    }

    /**
     * @dev Getter for total amount of staked tokens by user.
     */
    function getCurrentStake(address user) external view returns (uint256) {
        return getCurrentLockedStake(user) + getCurrentStakeWithCoolOff(user);
    }

    /**
     * @dev Wrappers around stake functions to pull the tokens from the user before staking. The user is
     * expected to grant the ERC20 approval for the sufficient amount of tokens to the contract address
     * before calling these functions, otherwise the transaction will revert.
     */
    function stakeTokensWithCoolOff(uint256 amount) external {
        _pullStakedTokens(amount);
        _stakeTokensWithCoolOff(amount);
    }

    function stakeTokensWithLock(
        uint256 newLockedAmount,
        uint256 intendedStakingLockPeriod,
        uint256 intendedVipMembershipThreshold
    ) external {
        uint256 currentLockedStake = getCurrentLockedStake(msg.sender);

        if (newLockedAmount <= currentLockedStake) {
            revert NewStakeNotHigherThanCurrent();
        }

        uint256 amount = newLockedAmount - currentLockedStake;
        _pullStakedTokens(amount);
        _stakeTokensWithLock(amount, intendedStakingLockPeriod, intendedVipMembershipThreshold);
    }

    /**
     * @dev Wrappers around staking with cool-off unstake function. If no amount is specified, the full amount is unstaked.
     */
    function unstakeTokensWithCoolOff(uint256 amount) external {
        _unstakeTokensWithCoolOff(amount);
    }

    function unstakeTokensWithCoolOff() external {
        uint256 amount = getCurrentStakeWithCoolOff(msg.sender);
        _unstakeTokensWithCoolOff(amount);
    }

    function _unstakeTokensWithCoolOff(uint256 amount) internal override {
        totalStakedAmount -= amount;
        totalUnstakedTokens += amount;
        super._unstakeTokensWithCoolOff(amount);
    }

    /**
     * @dev Function to withdraw unstaked tokens after the cool off period. This function does not transfer rewards
     * (ETH) to the user, they remain in the contract and can be withdrawn by calling the `withdrawRewards` function.
     */
    function withdrawUnstakedTokens() external {
        uint256 amount = _prepareTokensWithdrawal(msg.sender);
        totalUnstakedTokens -= amount;
        _transferWithdrawnTokens(msg.sender, amount);
    }

    /**
     * @dev Wrappers around staking with lock withdraw function. If no amount is specified, the full amount is withdrawn.
     */
    function withdrawLockedTokens(uint256 amount) external {
        _withdrawLockedTokens(amount);
    }

    function withdrawLockedTokens() external {
        uint256 amount = getCurrentLockedStake(msg.sender);
        _withdrawLockedTokens(amount);
    }

    function _withdrawLockedTokens(uint256 amount) internal {
        totalStakedAmount -= amount;
        _handleLockedTokensWithdrawal(amount);
        _transferWithdrawnTokens(msg.sender, amount);
    }

    /**
     * @dev Function to withdraw staking rewards. The staked tokens are not affected, only the rewards
     * are transferred to the user. The staking `rewardsStartIndex` resets to the current last index,
     * meaning that the rewards currently in the array won't be claimable again.
     */
    function withdrawRewards() external {
        uint256 amount = getCurrentRewards(msg.sender);

        if (amount == 0) {
            revert AmountIsZero();
        }

        uint256 lastRewardsIndex = _getLastRewardsIndex();

        userBalances[msg.sender] = 0;
        userStakingsWithCoolOff[msg.sender].rewardsStartIndex = lastRewardsIndex;
        userStakingsWithLock[msg.sender].rewardsStartIndex = lastRewardsIndex;

        _transferEth(msg.sender, amount);

        emit RewardsWithdrawal(msg.sender, amount);
    }

    /**
     * @dev Function to withdraw any ERC20 tokens that were sent to the contract by mistake.
     * When withdrawing the GOOD tokens, we have to substract the staked amount from the total balance.
     */
    function withdrawERC20(address erc20address) external onlyOwner {
        uint256 balance = IERC20(erc20address).balanceOf(address(this));
        uint256 amountToWithdraw =
            erc20address == goodTokenAddress ? balance - totalStakedAmount - totalUnstakedTokens : balance;

        if (amountToWithdraw == 0) {
            revert NoTokensToWithdraw(erc20address);
        }

        _transferERC20(erc20address, msg.sender, amountToWithdraw);
        emit OwnerERC20Withdrawal(msg.sender, erc20address, amountToWithdraw);
    }

    /**
     * @dev Functions to update staking parameters.
     */
    function updateVipMembershipThreshold(uint256 newThreshold) external onlyOwner {
        _updateVipMembershipThreshold(newThreshold);
    }

    function updateStakingLockPeriod(uint256 newLockPeriod) external onlyOwner {
        _updateStakingLockPeriod(newLockPeriod);
    }

    /**
     * @dev Returns last index of the `rewardsPerToken` array.
     */
    function _getLastRewardsIndex()
        internal
        view
        override(StakingPoolWithCoolOff, StakingPoolWithLock)
        returns (uint256)
    {
        return rewardsPerToken.length - 1;
    }

    /**
     * @dev Calculates the rewards for a given staking since its last update. The rewards are calculated as a difference between the current
     * accumulated rewards per token and the accumulated rewards per token at the time of staking, muliplied by the amount of staked tokens.
     * This does not include user balance in the `userBalances` variable, which stores the previous rewards in case user has changed the amount
     * of staked tokens.
     */
    function _calculateStakingRewards(StakingWithCoolOff storage staking) internal view returns (uint256) {
        return _calculateStakingRewards(staking.rewardsStartIndex, staking.amount);
    }

    function _calculateStakingRewards(StakingWithLock storage staking) internal view returns (uint256) {
        return _calculateStakingRewards(staking.rewardsStartIndex, staking.amount);
    }

    function _calculateStakingRewards(uint256 startIndex, uint256 amount) internal view returns (uint256) {
        uint256 rewardPerTokenUnit = rewardsPerToken[_getLastRewardsIndex()] - rewardsPerToken[startIndex];
        return (rewardPerTokenUnit * amount) / PRECISION;
    }

    /**
     * @dev Function to add the existing rewards to the user balance, in case the user has changed the amount of staked tokens. Used by the
     * `StakingPoolWithCoolOff` and `StakingPoolWithLock` contracts.
     */
    function _addRewardsToUserBalance(uint256 startIndex, uint256 amount)
        internal
        override(StakingPoolWithCoolOff, StakingPoolWithLock)
    {
        userBalances[msg.sender] += _calculateStakingRewards(startIndex, amount);
    }

    /**
     * @dev Pulls staked tokens from the user and increases the total staked amount. To be called when staking new tokens.
     */
    function _pullStakedTokens(uint256 amount) internal {
        if (amount == 0) {
            revert AmountIsZero();
        }

        totalStakedAmount += amount;
        IERC20(goodTokenAddress).safeTransferFrom(msg.sender, address(this), amount);
    }

    function _transferERC20(address erc20address, address recipient, uint256 amount) internal {
        IERC20(erc20address).safeTransfer(recipient, amount);
    }

    function _transferWithdrawnTokens(address recipient, uint256 amount) internal {
        _transferERC20(goodTokenAddress, recipient, amount);
    }

    function _transferEth(address recipient, uint256 amount) internal {
        (bool isSent,) = recipient.call{value: amount}("");

        if (!isSent) {
            revert EthTransferFailed();
        }
    }
}
