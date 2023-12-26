//SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./ILynxStaking.sol";
import "./ILynxVault.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

error LYNXStaking__InvalidDepositAmount();
error LYNXStaking__InvalidAprSelected();
error LYNXStaking__WithdrawLocked(uint lockEndTime);

contract LynxStaking is ILynxStaking, ReentrancyGuard {
    //--------------------------------------------------------------------
    // State Variables
    //--------------------------------------------------------------------
    mapping(address => Stake) public stake;
    uint256 private immutable apr;
    uint256 private immutable dur;
    AprConfig public aprConfig;

    address[] public stakers;
    IERC20 public lynx;
    ILynxVault public vault;
    uint256 public totalStaked;
    uint256 public totalClaimed;
    uint256 public constant REWARD_APR_BASE = 100_00; // 100.00%
    uint256 public immutable LockStart;

    //--------------------------------------------------------------------
    // Construtor
    //--------------------------------------------------------------------
    /**
     * @notice Constructor to set up the contract
     * @param weekStart - timestamp of when the weeks start
     * @param _lynx - address of lynx token.
     * @param _vault - address of vault that holds lynx to send/withdraw funds from
     * @param _apr - the expected APR to give back to users.
     * @param time_lock - the amount of weeks to lock tokens for
     */
    constructor(
        uint weekStart,
        address _lynx,
        address _vault,
        uint _apr,
        uint256 time_lock
    ) {
        time_lock = time_lock * 1 weeks;
        LockStart = weekStart;
        apr = _apr;
        dur = time_lock;
        aprConfig = AprConfig(true, _apr, time_lock);
        lynx = IERC20(_lynx);
        vault = ILynxVault(_vault);
    }

    //--------------------------------------------------------------------
    // External / Public Functions
    //--------------------------------------------------------------------
    function deposit(uint amount) external nonReentrant {
        if (amount == 0) revert LYNXStaking__InvalidDepositAmount();
        Stake storage currentStake = stake[msg.sender];
        uint256 duration = dur;

        if (currentStake.set) {
            uint reward = currentRewards(msg.sender);
            // IF reward time is over, claim rewards and reset the user
            if (currentStake.rewardEnd < block.timestamp) {
                // claim rewards
                totalClaimed += reward + currentStake.lockedRewards;
                currentStake.lockedRewards = 0;
                vault.withdrawTo(msg.sender, reward);
                emit ClaimRewards(msg.sender, reward);
            }
            // ELSE
            else {
                // lock rewards accrued so far and add the new deposit to the existing one
                currentStake.lockedRewards += reward;
                emit LockedRewards(msg.sender, reward);
            }
            currentStake.depositAmount += amount;
        } else {
            currentStake.depositAmount = amount;
            currentStake.posIndex = stakers.length;
            currentStake.set = true;
            stakers.push(msg.sender);
        }
        totalStaked += amount;
        currentStake.startStake = block.timestamp;
        currentStake.rewardEnd = calculateEndTime(duration);
        // Transfer Deposit amounts to Vault
        lynx.transferFrom(msg.sender, address(vault), amount);
        emit Deposit(msg.sender, amount, duration, currentStake.rewardEnd);
    }

    function withdraw() external nonReentrant {
        Stake storage currentStake = stake[msg.sender];
        if (block.timestamp < currentStake.rewardEnd)
            revert LYNXStaking__WithdrawLocked(currentStake.rewardEnd);

        // Claim rewards
        uint reward = currentRewards(msg.sender);
        reward += currentStake.lockedRewards;
        emit ClaimRewards(msg.sender, reward);
        reward += currentStake.depositAmount;
        emit Withdraw(msg.sender, currentStake.depositAmount);
        // remove user from stake list
        address lastIdxUser = stakers[stakers.length - 1];
        stakers[currentStake.posIndex] = lastIdxUser;
        stake[lastIdxUser].posIndex = currentStake.posIndex;
        stakers.pop();
        totalStaked -= currentStake.depositAmount;
        // reset the user
        stake[msg.sender] = Stake(0, 0, 0, 0, 0, false);
        vault.withdrawTo(msg.sender, reward);
    }

    function currentRewards(address user) public view returns (uint256) {
        Stake storage currentStake = stake[user];

        if (currentStake.depositAmount == 0 || !currentStake.set) return 0;

        uint256 rewardEnd = currentStake.rewardEnd;
        uint256 rewardAmount = 0;

        if (block.timestamp > rewardEnd) {
            rewardAmount = rewardEnd - currentStake.startStake;
        } else {
            rewardAmount = block.timestamp - currentStake.startStake;
        }

        rewardAmount =
            (currentStake.depositAmount * rewardAmount * apr) /
            (REWARD_APR_BASE * 365 days);

        return rewardAmount;
    }

    function calculateEndTime(uint256 duration) public view returns (uint256) {
        uint currentWeek = (block.timestamp - LockStart) / 1 weeks;
        return LockStart + (currentWeek * 1 weeks) + duration + 1 weeks;
    }

    function getStakers()
        external
        view
        returns (address[] memory users, uint256[] memory balances)
    {
        users = new address[](stakers.length);
        balances = new uint256[](stakers.length);
        for (uint i = 0; i < stakers.length; i++) {
            users[i] = stakers[i];
            balances[i] = stake[stakers[i]].depositAmount;
        }
    }
}
