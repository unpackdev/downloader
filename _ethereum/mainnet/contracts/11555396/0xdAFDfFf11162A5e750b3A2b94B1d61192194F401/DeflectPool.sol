pragma solidity ^0.6.0;

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


/**
 * @title DeflectPool
 * @author DEFLECT PROTOCOL
 * @dev This contract is a time-based yield farming pool with effective-staking multiplier mechanics.
 *
 * * * NOTE: A withdrawal fee of 1.5% is included which is sent to the treasury address. * * *
 */

contract DEFLCTROOT is LPTokenWrapper, OwnableUpgradeSafe {
    using SafeERC20 for IERC20;

    IERC20 public rewardToken;
    IDeflector deflector;
    uint256 public DURATION;
    uint256 public periodFinish;
    uint256 public lastUpdateTime;
    uint256 public rewardRate;
    uint256 public rewardPerTokenStored;
    uint256 public deployedTime;
    address public devFund;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardAdded(uint256 reward);
    event Withdrawn(address indexed user, uint256 amount);
    event Staked(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event Boost(address _token, uint256 level);

    constructor(
        uint256 _duration,
        address _stakingToken,
        address _rewardToken,
        address _deflector,
        address _treasury,
        address _devFund
    ) public LPTokenWrapper() {
        __Ownable_init();
        setStakingToken(_stakingToken);
        deflector = IDeflector(_deflector);
        treasury = _treasury;
        devFund = _devFund;
        devFee = 15; // 1.5%
        rewardToken = IERC20(_rewardToken);
        deployedTime = block.timestamp;
        DURATION = _duration;
    }

    function setNewTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
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
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        // Effective total supply takes into account all the multipliers bought by userbase.
        uint256 effectiveTotalSupply = _totalSupply.add(_totalSupplyAccounting);
        // The returrn value is time-based on last time the contract had rewards active multipliede by the reward-rate.
        // It's evened out with a division of bonus effective supply.
        return rewardPerTokenStored.add(lastTimeRewardsActive().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(effectiveTotalSupply));
    }

    /** @dev Returns the claimable tokens for user.*/
    function earned(address account) public view returns (uint256) {
        // Do a lookup for the multiplier on the view - it's necessary for correct reward distribution.
        // A user might have staked while owning global multiplier tokens but sold them and not acted in the contract after that.
        // So we do a recheck of the correct multiplier value here.
        uint256 totalMultiplier = deflector.getTotalValueForUser(address(this), account);
        uint256 effectiveBalance = _balances[account].add(_balances[account].mul(totalMultiplier).div(1000));
        return effectiveBalance.mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    /** @dev Staking function which updates the user balances in the parent contract */
    function stake(uint256 amount) public override {
        updateReward(msg.sender);
        require(amount > 0, "Cannot stake 0");

        // Call the parent to adjust the balances.
        super.stake(amount);

        // Get users multiplier.
        uint256 userTotalMultiplier = deflector.getTotalValueForUser(address(this), msg.sender);

        // Adjust the bonus effective stake according to the multiplier.
        adjustEffectiveStake(msg.sender, userTotalMultiplier, false);
        emit Staked(msg.sender, amount);
    }

    /** @dev Withdraw function, this pool contains a tax which is defined in the constructor */
    function withdraw(uint256 amount) public override {
        require(amount > 0, "Cannot withdraw 0");
        updateReward(msg.sender);

        // Calculate the withdraw tax (it's 1.5% of the amount)
        uint256 tax = amount.mul(devFee).div(1000);

        // Transfer the tokens to user
        stakingToken.safeTransfer(msg.sender, amount.sub(tax));
        // Tax to treasury
        stakingToken.safeTransfer(treasury, tax);

        // Adjust regular balances
        super.withdraw(amount);

        // And the bonus balances
        uint256 userTotalMultiplier = deflector.getTotalValueForUser(address(this), msg.sender);
        adjustEffectiveStake(msg.sender, userTotalMultiplier, true);
        emit Withdrawn(msg.sender, amount);
    }

    /** @dev Adjust the bonus effective stakee for user and whole userbase */
    function adjustEffectiveStake(
        address self,
        uint256 _totalMultiplier,
        bool _isWithdraw
    ) private {
        uint256 prevBalancesAccounting = _balancesAccounting[self];
        if (_totalMultiplier > 0) {
            // Calculate and set self's new accounting balance
            uint256 newBalancesAccounting = _balances[self].mul(_totalMultiplier).div(1000);

            // Adjust total accounting supply accordingly - Subtracting previous balance from new balance on withdraws
            // On deposits it's vice-versa.
            if (_isWithdraw) {
                uint256 diffBalancesAccounting = prevBalancesAccounting.sub(newBalancesAccounting);
                _balancesAccounting[self] = _balancesAccounting[self].sub(diffBalancesAccounting);
                _totalSupplyAccounting = _totalSupplyAccounting.sub(diffBalancesAccounting);
            } else {
                uint256 diffBalancesAccounting = newBalancesAccounting.sub(prevBalancesAccounting);
                _balancesAccounting[self] = _balancesAccounting[self].add(diffBalancesAccounting);
                _totalSupplyAccounting = _totalSupplyAccounting.add(diffBalancesAccounting);
            }
        } else {
            _balancesAccounting[self] = 0;
            _totalSupplyAccounting = _totalSupplyAccounting.sub(prevBalancesAccounting);
        }
    }

    // Ease-of-access function for user to remove assets from the pool.
    function exit() external {
        getReward();
        withdraw(balanceOf(msg.sender));
    }

    // Sends out the reward tokens to the user.
    function getReward() public {
        updateReward(msg.sender);
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    // Called to start the pool with the reward amount it should distribute
    // The reward period will be the duration of the pool.
    function notifyRewardAmount(uint256 reward) external onlyOwner {
        // Pull the funds from the owner
        rewardToken.safeTransferFrom(msg.sender, address(this), reward);
        // Update reward values
        updateRewardPerTokenStored();

        // Rewardrate must stay at a constant since it's used by end-users claiming rewards after the reward period has finished.
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(DURATION);
        } else {
            // Remaining time for the pool
            uint256 remainingTime = periodFinish.sub(block.timestamp);
            // And the rewards
            uint256 rewardsRemaining = remainingTime.mul(rewardRate);
            // Set the current rate
            rewardRate = reward.add(rewardsRemaining).div(DURATION);
        }

        // Set the last updated
        lastUpdateTime = block.timestamp;
        startTime = block.timestamp;
        // Add the period to be equal to duration set.s
        periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(reward);
    }

    // Notify a reward amount without updating time,
    function notifyRewardAmountWithoutUpdateTime(uint256 reward) external onlyOwner {
        rewardToken.safeTransferFrom(msg.sender, address(this), reward);
        updateRewardPerTokenStored();
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(DURATION);
        }
        emit RewardAdded(reward);
    }

    // Returns the users current multiplier level
    function getTotalLevel(address _user) external view returns (uint256) {
        return deflector.getTotalLevel(address(this), _user);
    }

    // Return the amount spent on multipliers, used for subtracting for future purchases.
    function getSpent(address _token, address _user) external view returns (uint256) {
        return deflector.getTokensSpentPerContract(address(this), _token, _user);
    }

    // Calculate the cost for purchasing a boost.
    function calculateCost(
        address _user,
        address _token,
        uint256 _level
    ) public view returns (uint256) {
        // Users last level, no cost for levels lower than current (doh)
        uint256 lastLevel = deflector.getLastTokenLevelForUser(address(this), _user, _token);
        if (lastLevel >= _level) {
            return 0;
        } else {
            return deflector.getSpendableCostPerTokenForUser(address(this), _user, _token, _level);
        }
    }

    // Purchase a multiplier level, same level cannot be purchased twice.
    function purchase(address _token, uint256 _newLevel) external {
        // Must be a spendable token
        require(deflector.isSpendableTokenInContract(address(this), _token), "Not a spendable token");

        // What's the last level for the user? s
        uint256 lastLevel = deflector.getLastTokenLevelForUser(address(this), msg.sender, _token);
        require(lastLevel < _newLevel, "Cannot downgrade level or same level");

        // Get the subtracted cost for the new level.
        uint256 cost = calculateCost(msg.sender, _token, _newLevel);

        // Transfer the bonus cost into the treasury and dev fund.
        IERC20(_token).safeTransferFrom(msg.sender, devFund, cost.mul(25).div(100));
        IERC20(_token).safeTransferFrom(msg.sender, treasury, cost.mul(75).div(100));

        // Update balances and level in the multiplier contarct
        deflector.purchase(address(this), msg.sender, _token, _newLevel);

        // Adjust new level
        uint256 userTotalMultiplier = deflector.getTotalValueForUser(address(this), msg.sender);
        adjustEffectiveStake(msg.sender, userTotalMultiplier, false);

        emit Boost(_token, _newLevel);
    }

    // Returns the multiplier for user.
    function getTotalMultiplier(address _account) public view returns (uint256) {
        return deflector.getTotalValueForUser(address(this), _account);
    }

    // Ejects any remaining tokens from the pool.
    // Callable only after the pool has started and the pools reward distribution period has finished.
    function eject() external onlyOwner {
        require(startTime < block.timestamp && block.timestamp >= periodFinish, "Cannot eject before period finishes or pool has started");
        uint256 currBalance = rewardToken.balanceOf(address(this));
        rewardToken.safeTransfer(msg.sender, currBalance);
    }

    // Forcefully retire a pool
    // Only sets the period finish to 0
    // This will prevent more rewards from being disbursed
    function kill() external onlyOwner {
        periodFinish = block.timestamp;
    }

    function updateRewardPerTokenStored() internal {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardsActive();
    }

    function updateReward(address account) internal {
        updateRewardPerTokenStored();
        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }
}
