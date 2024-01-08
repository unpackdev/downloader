//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/*
    ▓█████▄ ▓█████   ████ ▒██▓    ▓█████  ▄████▄  ▄▄▄█████▓   ██▓███   ▒█████   ▒█████   ██▓
    ▒██▀ ██▌▓█   ▀  ▓██   ▒▓██▒    ▓█   ▀ ▒██▀ ▀█  ▓  ██▒ ▓▒   ▓██░  ██▒▒██▒  ██▒▒██▒  ██▒ ▓██▒
    ░██   █▌▒███    ▒████ ░▒██░    ▒███   ▒▓█    ▄    ██░ ▒    ▓██░ ██▓▒▒██   ██▒▒██░  ██▒ ▒██░
    ░▓█▄   ▌▒▓█  ▄ ░ ▓█▒  ░▒██░    ▒▓█  ▄ ▒▓▓▄ ▄██▒░  ██ ░    ▒██▄█▓▒ ▒▒██   ██░▒██   ██░ ▒██░
    ░▒████▓ ░▒████▒░ ▒█░   ░██████▒░▒████▒▒ ▓███▀ ░  ▒██▒     ▒██▒ ░  ░░ ████▓▒░░ ████▓▒░░██████▒
     ▒▒▓  ▒ ░░ ▒░ ░ ▒ ░   ░ ▒░▓  ░░░ ▒░ ░░ ░▒ ▒  ░  ▒ ░░        ▒▓▒░ ░  ░░ ▒░▒░▒░ ░ ▒░▒░▒░ ░ ▒░▓  ░
     ░ ▒  ▒  ░ ░  ░ ░     ░ ░ ▒  ░ ░ ░  ░  ░  ▒       ░          ░▒ ░       ░ ▒ ▒░   ░ ▒ ▒░ ░ ░ ▒  ░
     ░ ░  ░    ░    ░ ░     ░ ░      ░   ░             ░             ░░         ░ ░ ░ ▒  ░ ░ ░ ▒


*/

import "./Ownable.sol";
import "./Math.sol";
import "./LPTokenWrapper.sol";
import "./IDeflector.sol";
import "./IERC20Metadata.sol";

/**
 * @title DeflectPool
 * @author DEFLECT PROTOCOL
 * @dev This contract is a time-based yield farming pool with effective-staking multiplier mechanics.
 *
 * * * NOTE: A withdrawal fee of 1.5% is included which is sent to the treasury address. * * *
 */

contract DeflectPoolRewardLock is LPTokenWrapper, Ownable {
    using SafeERC20 for IERC20Metadata;

    IERC20Metadata public immutable rewardToken;
    uint256 public immutable stakingTokenMultiplier;
    IDeflector public immutable deflector;
    uint256 public immutable duration;
    uint256 public immutable deployedTime;
    address public immutable devFund;

    uint256 public periodFinish;
    uint256 public lockTime;
    uint256 public lastUpdateTime;
    uint256 public rewardRate;
    uint256 public rewardPerTokenStored;

    struct RewardInfo {
        uint256 rewards;
        uint256 userRewardPerTokenPaid;
    }

    mapping(address => RewardInfo) public rewards;

    event RewardAdded(uint256 reward);
    event Withdrawn(address indexed user, uint256 amount);
    event Staked(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event Boost(address _token, uint256 level);

    // Set the staking token for the contract
    constructor(
        uint256 _duration,
        address _stakingToken,
        IERC20Metadata _rewardToken,
        address _deflector,
        address _treasury,
        address _devFund,
        uint256 _devFee
    ) public LPTokenWrapper(_devFee, _stakingToken, _treasury) Ownable() {
        require(_duration != 0 && _stakingToken != address(0) && _rewardToken != IERC20Metadata(0) && _deflector != address(0) && _treasury != address(0) && _devFund != address(0), "!constructor");
        deflector = IDeflector(_deflector);
        stakingTokenMultiplier = 10**uint256(IERC20Metadata(_stakingToken).decimals());
        rewardToken = _rewardToken;
        duration = _duration;
        deployedTime = block.timestamp;
        devFund = _devFund;
    }

    function setNewTreasury(address _treasury) external onlyOwner() {
        treasury = _treasury;
    }

    function setLockTime(uint256 _lockTime) external onlyOwner() {
        lockTime = _lockTime;
    }
    
    function lastTimeRewardsActive() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    /* @dev Returns the current rate of rewards per token (doh) */
    function rewardPerToken() public view returns (uint256) {
        // Do not distribute rewards before startTime.
        if (block.timestamp < startTime) {
            return 0;
        }

        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }

        // Effective total supply takes into account all the multipliers bought by userbase.
        uint256 effectiveTotalSupply = totalSupply.add(boostedTotalSupply);
        // The returrn value is time-based on last time the contract had rewards active multipliede by the reward-rate.
        // It's evened out with a division of bonus effective supply.
        return rewardPerTokenStored
        .add(
            lastTimeRewardsActive()
            .sub(lastUpdateTime)
            .mul(rewardRate)
            .mul(stakingTokenMultiplier)
            .div(effectiveTotalSupply)
        );
    }

    /** @dev Returns the claimable tokens for user.*/
    function earned(address account) public view returns (uint256) {
        uint256 effectiveBalance = _balances[account].balance.add(_balances[account].boostedBalance);
        RewardInfo memory userRewards = rewards[account];
        return effectiveBalance.mul(rewardPerToken().sub(userRewards.userRewardPerTokenPaid)).div(stakingTokenMultiplier).add(userRewards.rewards);
    }

    /** @dev Staking function which updates the user balances in the parent contract */
    function stake(uint256 amount) public override {
        require(amount > 0, "Cannot stake 0");
        updateReward(msg.sender);

        // Call the parent to adjust the balances.
        super.stake(amount);

        // Adjust the bonus effective stake according to the multiplier.
        uint256 boostedBalance = deflector.calculateBoostedBalance(msg.sender, _balances[msg.sender].balance);
        adjustBoostedBalance(boostedBalance);
        emit Staked(msg.sender, amount);
    }

    /** @dev Withdraw function, this pool contains a tax which is defined in the constructor */
    function withdraw(uint256 amount) public override {
        require(amount > 0, "Cannot withdraw 0");
        updateReward(msg.sender);

        // Adjust regular balances
        super.withdraw(amount);

        // And the bonus balances
        uint256 boostedBalance = deflector.calculateBoostedBalance(msg.sender, _balances[msg.sender].balance);
        adjustBoostedBalance(boostedBalance);
        emit Withdrawn(msg.sender, amount);
    }

    /** @dev Adjust the bonus effective stakee for user and whole userbase */
    function adjustBoostedBalance(uint256 _boostedBalance) private {
        Balance storage balances = _balances[msg.sender];
        uint256 previousBoostedBalance = balances.boostedBalance;
        if (_boostedBalance > 0) {
            if (_boostedBalance < previousBoostedBalance) {
                uint256 diffBalancesAccounting = previousBoostedBalance.sub(_boostedBalance);
                boostedTotalSupply = boostedTotalSupply.sub(diffBalancesAccounting);
            } else {
                uint256 diffBalancesAccounting = _boostedBalance.sub(previousBoostedBalance);
                boostedTotalSupply = boostedTotalSupply.add(diffBalancesAccounting);
            }

            balances.boostedBalance = _boostedBalance;
        }
    }

    // Ease-of-access function for user to remove assets from the pool.
    function exit() external {
        if(block.timestamp >= lockTime) {
             getReward();
        }
        withdraw(balanceOf(msg.sender));
    }

    // Sends out the reward tokens to the user.
    function getReward() public {
        require(block.timestamp >= lockTime,"Can-not-get-reward-now");
        updateReward(msg.sender);
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender].rewards = 0;
            emit RewardPaid(msg.sender, reward);
            rewardToken.safeTransfer(msg.sender, reward);
        }
    }

    // Called to start the pool.
    // Owner must send rewards to the contract and the balance of this token is used as the reward to account for fee on transfer tokens.
    // The reward period will be the duration of the pool.
    function notifyRewardAmount(uint256 _lockDuration) external onlyOwner() {
        uint256 reward = rewardToken.balanceOf(address(this));
        require(reward > 0, "!reward added");
        lockTime = block.timestamp.add(_lockDuration); // current time stamp add duration
        // Update reward values
        updateRewardPerTokenStored();

        // Rewardrate must stay at a constant since it's used by end-users claiming rewards after the reward period has finished.
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(duration);
        } else {
            // Remaining time for the pool
            uint256 remainingTime = periodFinish.sub(block.timestamp);
            // And the rewards
            uint256 rewardsRemaining = remainingTime.mul(rewardRate);
            // Set the current rate
            rewardRate = reward.add(rewardsRemaining).div(duration);
        }

        // Set the last updated
        lastUpdateTime = block.timestamp;
        startTime = block.timestamp;
        // Add the period to be equal to duration set.s
        periodFinish = block.timestamp.add(duration);
        emit RewardAdded(reward);
    }

    // Purchase a multiplier level, same level cannot be purchased twice.
    function purchase(address _token, uint256 _newLevel) external {
        require(block.timestamp < periodFinish, "cannot buy after pool ends");

        updateReward(msg.sender);
        
        // Calculates cost, ensures it is a new level too
        uint256 cost = deflector.calculateCost(msg.sender, _token, _newLevel);
        require(cost > 0, "cost cannot be 0");

        // Update level in multiplier contract
        uint256 newBoostedBalance = deflector.updateLevel(msg.sender, _token, _newLevel, _balances[msg.sender].balance);

        // Adjust new level
        adjustBoostedBalance(newBoostedBalance);

        emit Boost(_token, _newLevel);

        uint256 actualCost = cost.mul(periodFinish - block.timestamp).div(duration);

        uint256 devPortion = actualCost.mul(25) / 100;

        // Transfer the bonus cost into the treasury and dev fund.
        IERC20Metadata(_token).safeTransferFrom(msg.sender, devFund, devPortion);
        IERC20Metadata(_token).safeTransferFrom(msg.sender, treasury, actualCost - devPortion);
    }

    // Sync after minting more prism
    function sync() external {
        updateReward(msg.sender);

        uint256 boostedBalance = deflector.calculateBoostedBalance(msg.sender, _balances[msg.sender].balance);
        require(boostedBalance > _balances[msg.sender].boostedBalance, "DeflectPool::sync: Invalid sync invocation");
        // Adjust new level
        adjustBoostedBalance(boostedBalance);
    }

    // Returns the multiplier for user.
    function getUserMultiplier() external view returns (uint256) {
         // And the bonus balances
        uint256 boostedBalance = deflector.calculateBoostedBalance(msg.sender, _balances[msg.sender].balance);
        
        if (boostedBalance == 0) return 0;

        return boostedBalance * 100 / _balances[msg.sender].balance;
    }

    function getLevelCost(address _token, uint256 _level) external view returns (uint256) {
        return deflector.calculateCost(msg.sender, _token, _level);
    }

    // Ejects any remaining tokens from the pool.
    // Callable only after the pool has started and the pools reward distribution period has finished.
    function eject() external onlyOwner() {
        require(block.timestamp >= periodFinish + 12 hours, "Cannot eject before period finishes or pool has started");
        uint256 currBalance = rewardToken.balanceOf(address(this));
        rewardToken.safeTransfer(msg.sender, currBalance);
    }

    // Forcefully retire a pool
    // Only sets the period finish to 0
    // This will prevent more rewards from being disbursed
    function kill() external onlyOwner() {
        periodFinish = block.timestamp;
    }

    // Callable only after the pool has started and the pools reward distribution period has finished.
    function emergencyWithdraw() external {
        require(block.timestamp >= periodFinish + 12 hours, "DeflectPool::emergencyWithdraw: Cannot emergency withdraw before period finishes or pool has started");
        uint256 fullWithdrawal = balanceOf(msg.sender);
        require(fullWithdrawal > 0, "DeflectPool::emergencyWithdraw: Cannot withdraw 0");
        super.withdraw(fullWithdrawal);
        emit Withdrawn(msg.sender, fullWithdrawal);
    }

    function updateRewardPerTokenStored() internal {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardsActive();
    }

    function updateReward(address account) internal {
        updateRewardPerTokenStored();
        rewards[account].rewards = earned(account);
        rewards[account].userRewardPerTokenPaid = rewardPerTokenStored;
    }
}
