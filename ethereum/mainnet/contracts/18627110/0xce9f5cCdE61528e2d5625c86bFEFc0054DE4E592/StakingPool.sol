// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

error EthTransferFailed();
error AmountIsZero();
error AmountGreaterThanStake();
error WithdrawalLocked();
error NoStakedTokens();
error NoTokensToWithdraw(address erc20address);

struct Staking {
    uint256 startIndex;
    uint256 amount;
    uint256 lockedUntil;
}

/**
 * @dev This contract allows staking of the ERC20 tokens and rewards the stakers with ETH. The contract address is required to be whitelisted / exempt
 * from GOOD token transfer fees for it to work properly. When new rewards (ETH) are deposited to the contract, every staker receives a proportional
 * share of the rewards with respect to the amount of tokens staked. The contract records historical deposits of rewards into the contract and use
 * them to calculate user rewards during their withdrawal. Users are able to stake, unstake and update the amount of staked tokens, but they are not
 * able to withdraw staked tokens for a certain period of time after staking (unstakingPeriod). Users are able to withdraw their rewards at any time.
 * After the contract is deployed, there is period of 1 day (launchLockPeriod), during which no rewards are distributed. This is to prevent
 * the situation, where the first staker would receive all the rewards after the GOOD token is launched.
 *
 * When rewards are received by the contract, it calculates the proportional value of incoming rewards per staked token and stores it in the
 * `rewardsPerToken` array. The array is a prefix sum array, so that the sum of rewards per token can be calculated in constant time simply
 * by substracting the value at the time of staking (startIndex) from the last value in the array. The total reward for staking is then
 * found by multiplying the sum of rewards per token by the amount of staked tokens.
 */
contract StakingPool is Ownable {
    using SafeERC20 for IERC20;

    /**
     * @dev Arbitrary unit of reward calculation precision.
     * Calculated reward per token is an integer value, so if staked amount would be higher than that, we would lose precision for last digits.
     * Therefore we calculate the rewards per {{PRECISION}} tokens instead. Value of 10x the total supply of GOOD token is chosen, so that the
     * staked amounts are always lower than that.
     */
    uint256 internal constant PRECISION = 1e18 * 1e10;

    address public immutable erc20address;
    uint256 public immutable launchLockPeriodEnd;
    uint256 public immutable unstakingPeriod;
    uint256 public undistributedRewards;
    uint256 public totalStakedAmount;
    uint256 public totalDepositedRewards;

    mapping(address => uint256) internal userBalances;
    mapping(address => Staking) internal userStakings;

    uint256[] internal rewardsPerToken = [0];

    event TokensStaked(address indexed user, uint256 amount);
    event RewardsDeposit(uint256 amount);
    event StakedTokensWithdrawal(address indexed user, uint256 amount);
    event RewardsWithdrawal(address indexed user, uint256 amount);
    event RewardsAndStakedTokensWithdrawal(address indexed user, uint256 stakingAmount, uint256 rewardsAmount);
    event OwnerERC20Withdrawal(address indexed user, address indexed erc20address, uint256 amount);

    constructor(address erc20address_, uint256 launchLockPeriod_, uint256 unstakingPeriod_, address owner_)
        Ownable(owner_)
    {
        erc20address = erc20address_;
        unstakingPeriod = unstakingPeriod_;
        launchLockPeriodEnd = block.timestamp + launchLockPeriod_;
    }

    receive() external payable {
        depositStakingRewards();
    }

    /**
     * @dev Explicit function to deposit ETH rewards.
     * If no tokens are staked or launch lock period is not over yet, the rewards are accumulated in the `undistributedRewards` variable.
     * Otherwise the incoming rewards together with any `undistributedRewards` are "allocated" among stakers. This is done by calculating
     * the rewards per staked token and storing it in the `rewardsPerToken` prefix sum array.
     */
    function depositStakingRewards() public payable {
        emit RewardsDeposit(msg.value);

        totalDepositedRewards += msg.value;

        if (block.timestamp < launchLockPeriodEnd || totalStakedAmount == 0) {
            undistributedRewards += msg.value;
            return;
        }

        uint256 totalRewardAmount = msg.value + undistributedRewards;
        undistributedRewards = 0;
        uint256 rewardPerToken = (totalRewardAmount * PRECISION) / totalStakedAmount;

        rewardsPerToken.push(rewardsPerToken[_getLastRewardsIndex()] + rewardPerToken);
    }

    /**
     * @dev Getter for current amount of staked tokens.
     */
    function getCurrentStake(address user) public view returns (uint256) {
        return userStakings[user].amount;
    }

    /**
     * @dev Getter for current value of staking rewards.
     */
    function getCurrentRewards(address user) public view returns (uint256) {
        return userBalances[user] + _calculateStakingRewards(userStakings[user]);
    }

    /**
     * @dev Getter for the end of unstaking period. User cannot withdraw staked tokens during `unstakingPeriod` seconds after staking.
     */
    function getStakeWithdrawalLockedUntil(address user) external view returns (uint256) {
        if (getCurrentStake(user) == 0) {
            revert NoStakedTokens();
        }

        return userStakings[user].lockedUntil;
    }

    /**
     * @dev Function to stake tokens or to increase the existing stake. The user is expected to grant the ERC20 approval for the sufficient
     * amount of tokens to the contract address before calling this function, otherwise the transaction will revert. If user has already some
     * tokens staked, the current rewards are calculated and saved to the `userBalances` mapping and new staking is created with new total
     * amount of tokens staked. Staking `startIndex` points to the last unclaimable reward in the `rewardsPerToken` array, which is the last
     * index at the time of staking. Any new rewards that are added to the array will be included in the reward calculation for this staking.
     */
    function stakeTokens(uint256 amount) external {
        if (amount == 0) {
            revert AmountIsZero();
        }

        IERC20(erc20address).safeTransferFrom(msg.sender, address(this), amount);

        totalStakedAmount += amount;
        Staking storage staking = userStakings[msg.sender];
        uint256 stakedAmount = staking.amount;

        if (stakedAmount > 0) {
            userBalances[msg.sender] += _calculateStakingRewards(staking);
        }

        userStakings[msg.sender] = Staking({
            startIndex: _getLastRewardsIndex(),
            amount: stakedAmount + amount,
            lockedUntil: block.timestamp + unstakingPeriod
        });

        emit TokensStaked(msg.sender, amount);
    }

    /**
     * @dev Function to withdraw staked tokens and decrease the existing stake. The current rewards are calculated and saved to the `userBalances`
     * mapping and new staking is created with the remaining amount of staked tokens. This function does not transfer rewards (ETH) to the user,
     * they remain in the contract and can be withdrawn by calling `withdrawRewards` function.
     */
    function withdrawStakedTokens(uint256 amount) external {
        if (amount == 0) {
            revert AmountIsZero();
        }

        Staking storage staking = userStakings[msg.sender];

        if (staking.lockedUntil > block.timestamp) {
            revert WithdrawalLocked();
        }
        if (staking.amount < amount) {
            revert AmountGreaterThanStake();
        }

        totalStakedAmount -= amount;
        userBalances[msg.sender] += _calculateStakingRewards(staking);

        staking.startIndex = _getLastRewardsIndex();
        staking.amount -= amount;

        _transferERC20(erc20address, msg.sender, amount);

        emit StakedTokensWithdrawal(msg.sender, amount);
    }

    /**
     * @dev Function to withdraw staking rewards. The staked tokens are not affected, only the rewards are transferred to the user. The staking
     * `startIndex` resets to the current last index, meaning that the rewards currently in the array won't be claimable again.
     */
    function withdrawRewards() external {
        uint256 amount = getCurrentRewards(msg.sender);

        if (amount == 0) {
            revert AmountIsZero();
        }

        userBalances[msg.sender] = 0;
        userStakings[msg.sender].startIndex = _getLastRewardsIndex();

        _transferEth(msg.sender, amount);

        emit RewardsWithdrawal(msg.sender, amount);
    }

    /**
     * @dev Function to withdraw all staked tokens and all staking rewards. User will no longer have staked tokens after this function is called.
     */
    function withdrawRewardsAndStakedTokens() external {
        uint256 stakedAmount = getCurrentStake(msg.sender);

        if (stakedAmount == 0) {
            revert NoStakedTokens();
        }
        if (userStakings[msg.sender].lockedUntil > block.timestamp) {
            revert WithdrawalLocked();
        }

        totalStakedAmount -= stakedAmount;
        uint256 rewardsAmount = getCurrentRewards(msg.sender);

        userBalances[msg.sender] = 0;
        delete userStakings[msg.sender];

        _transferERC20(erc20address, msg.sender, stakedAmount);
        _transferEth(msg.sender, rewardsAmount);

        emit RewardsAndStakedTokensWithdrawal(msg.sender, stakedAmount, rewardsAmount);
    }

    /**
     * @dev Function to withdraw any ERC20 tokens that were sent to the contract by mistake.
     * When withdrawing the GOOD tokens, we have to substract the staked amount from the total balance.
     */
    function withdrawERC20(address erc20address_) external onlyOwner {
        uint256 balance = IERC20(erc20address_).balanceOf(address(this));
        uint256 amountToWithdraw = erc20address_ == erc20address ? balance - totalStakedAmount : balance;

        if (amountToWithdraw == 0) {
            revert NoTokensToWithdraw(erc20address_);
        }

        _transferERC20(erc20address_, msg.sender, amountToWithdraw);
        emit OwnerERC20Withdrawal(msg.sender, erc20address_, amountToWithdraw);
    }

    /**
     * @dev Returns last index of the `rewardsPerToken` array.
     */
    function _getLastRewardsIndex() internal view returns (uint256) {
        return rewardsPerToken.length - 1;
    }

    /**
     * @dev Calculates the rewards for a given staking since its last update. The rewards are calculated as a difference between the current
     * accumulated rewards per token and the accumulated rewards per token at the time of staking, muliplied by the amount of staked tokens.
     * This does not include user balance in the `userBalances` variable, which stores the previous rewards in case user has changed the amount
     * of staked tokens.
     */
    function _calculateStakingRewards(Staking storage staking) internal view returns (uint256) {
        uint256 rewardPerTokenUnit = rewardsPerToken[_getLastRewardsIndex()] - rewardsPerToken[staking.startIndex];
        return (rewardPerTokenUnit * staking.amount) / PRECISION;
    }

    function _transferEth(address recipient, uint256 amount) internal {
        (bool isSent,) = recipient.call{value: amount}("");

        if (!isSent) {
            revert EthTransferFailed();
        }
    }

    function _transferERC20(address erc20address_, address recipient, uint256 amount) internal {
        IERC20(erc20address_).safeTransfer(recipient, amount);
    }
}
