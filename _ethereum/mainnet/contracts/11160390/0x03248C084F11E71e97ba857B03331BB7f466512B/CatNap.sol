// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Ownable.sol";
import "./Math.sol";
import "./LPTokenWrapper.sol";

interface MultiplierInterface {
    function getPermanentMultiplier(address account)
        external
        view
        returns (uint256);
}

contract CatNap is LPTokenWrapper, Ownable {
    using SafeERC20 for IERC20;
    IERC20 public rewardToken;
    IERC20 public multiplierToken;
    MultiplierInterface public multiplier = MultiplierInterface(address(0));
    uint256 public DURATION;
    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public deployedTime;
    uint256 public multiplierDiscountRange;
    uint256 public boostLevelOneCost;
    uint256 public boostLevelTwoCost;
    uint256 public boostLevelThreeCost;
    uint256 public boostLevelFourCost;
    uint256 public boostLevelFiveCost;
    uint256 public boostLevelSixCost;
    uint256 public boostLevelOneBonus;
    uint256 public boostLevelTwoBonus;
    uint256 public boostLevelThreeBonus;
    uint256 public boostLevelFourBonus;
    uint256 public boostLevelFiveBonus;
    uint256 public boostLevelSixBonus;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public spentMultiplierTokens;
    mapping(address => uint256) public boostLevel;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event Boost(uint256 level);

    constructor(
        uint256 _duration,
        uint256 _multiplierDiscountRange,
        address _stakingToken,
        address _rewardToken,
        address _multiplierToken,
        uint256 _startTime,
        address _multiplierAddr
    ) public LPTokenWrapper(_startTime) {
        setStakingToken(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        multiplierToken = IERC20(_multiplierToken);
        deployedTime = block.timestamp;
        multiplier = MultiplierInterface(_multiplierAddr);
        multiplierDiscountRange = _multiplierDiscountRange;
        DURATION = _duration;
    }

    function setOwner(address _newOwner) external onlyOwner {
        super.transferOwnership(_newOwner);
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    // Returns the current rate of rewards per token (doh)
    function rewardPerToken() public view returns (uint256) {
        // Do not distribute rewards before games begin
        if (block.timestamp < startTime) {
            return 0;
        }
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        // Effective total supply takes into account all the multipliers bought.
        uint256 effectiveTotalSupply = _totalSupply.add(_totalSupplyAccounting);
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(effectiveTotalSupply)
            );
    }

    // Returns the current reward tokens that the user can claim.
    function earned(address account) public view returns (uint256) {
        // Each user has it's own effective balance which is just the staked balance multiplied by boost level multiplier.
        uint256 effectiveBalance = _balances[account].add(
            _balancesAccounting[account]
        );
        return
            effectiveBalance
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    // Staking function which updates the user balances in the parent contract
    function stake(uint256 amount) public override {
        updateReward(msg.sender);
        require(amount > 0, "Cannot stake 0");
        super.stake(amount);

        // Users that have bought multipliers will have an extra balance added to their stake according to the boost multiplier.
        if (boostLevel[msg.sender] > 0) {
            uint256 prevBalancesAccounting = _balancesAccounting[msg.sender];
            // Calculate and set user's new accounting balance
            uint256 accTotalMultiplier = getTotalMultiplier(msg.sender);
            uint256 newBalancesAccounting = _balances[msg.sender]
                .mul(accTotalMultiplier)
                .div(1e18)
                .sub(_balances[msg.sender]);
            _balancesAccounting[msg.sender] = newBalancesAccounting;
            // Adjust total accounting supply accordingly
            uint256 diffBalancesAccounting = newBalancesAccounting.sub(
                prevBalancesAccounting
            );
            _totalSupplyAccounting = _totalSupplyAccounting.add(
                diffBalancesAccounting
            );
        }

        emit Staked(msg.sender, amount);
    }

    // Withdraw function to remove stake from the pool
    function withdraw(uint256 amount) public override {
        require(amount > 0, "Cannot withdraw 0");
        updateReward(msg.sender);
        super.withdraw(amount);

        // Users who have bought multipliers will have their accounting balances readjusted.
        if (boostLevel[msg.sender] > 0) {
            // The previous extra balance user had
            uint256 prevBalancesAccounting = _balancesAccounting[msg.sender];
            // Calculate and set user's new accounting balance
            uint256 accTotalMultiplier = getTotalMultiplier(msg.sender);
            uint256 newBalancesAccounting = _balances[msg.sender]
                .mul(accTotalMultiplier)
                .div(1e18)
                .sub(_balances[msg.sender]);
            _balancesAccounting[msg.sender] = newBalancesAccounting;
            // Subtract the withdrawn amount from the accounting balance
            // If all tokens are withdrawn the balance will be 0.
            uint256 diffBalancesAccounting = prevBalancesAccounting.sub(
                newBalancesAccounting
            );
            _totalSupplyAccounting = _totalSupplyAccounting.sub(
                diffBalancesAccounting
            );
        }

        emit Withdrawn(msg.sender, amount);
    }

    // Get the earned rewards and withdraw staked tokens
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
            rewardToken.safeTransfer(msg.sender, reward.mul(96).div(100));
            rewardToken.safeTransfer(devFund, reward.mul(4).div(100));
            emit RewardPaid(msg.sender, reward);
        }
    }

    // Called to start the pool with the reward amount it should distribute
    // The reward period will be the duration of the pool.
    function notifyRewardAmount(uint256 reward) external onlyOwner {
        updateRewardPerTokenStored();
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(DURATION);
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(reward);
    }

    // Notify the reward amount without updating time;
    function notifyRewardAmountWithoutUpdateTime(uint256 reward)
        external
        onlyOwner
    {
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
    function getLevel(address account) external view returns (uint256) {
        return boostLevel[account];
    }

    // Return the amount spent on multipliers, used for subtracting for future purchases.
    function getSpent(address account) external view returns (uint256) {
        return spentMultiplierTokens[account];
    }

    // Calculate the cost for purchasing a boost.
    function calculateCost(uint256 level) public view returns (uint256) {
        uint256 cycles = calculateCycle(
            deployedTime,
            block.timestamp,
            multiplierDiscountRange
        );
        // Cap it to 5 times
        if (cycles > 5) {
            cycles = 5;
        }
        if (level == 1) {
            return boostLevelOneCost.mul(9**cycles).div(10**cycles);
        } else if (level == 2) {
            return boostLevelTwoCost.mul(9**cycles).div(10**cycles);
        } else if (level == 3) {
            return boostLevelThreeCost.mul(9**cycles).div(10**cycles);
        } else if (level == 4) {
            return boostLevelFourCost.mul(9**cycles).div(10**cycles);
        } else if (level == 5) {
            return boostLevelFiveCost.mul(9**cycles).div(10**cycles);
        } else if (level == 6) {
            return boostLevelSixCost.mul(9**cycles).div(10**cycles);
        }
    }

    // Purchase a multiplier level, same level cannot be purchased twice.
    function purchase(uint256 level) external {
        require(
            boostLevel[msg.sender] <= level,
            "Cannot downgrade level or same level"
        );
        uint256 cost = calculateCost(level);
        // Cost will be reduced by the amount already spent on multipliers.
        uint256 finalCost = cost.sub(spentMultiplierTokens[msg.sender]);

        multiplierToken.safeTransferFrom(msg.sender, devFund, finalCost);

        // Update balances and level
        spentMultiplierTokens[msg.sender] = spentMultiplierTokens[msg.sender]
            .add(finalCost);
        boostLevel[msg.sender] = level;

        // If user has staked balances, then set their new accounting balance
        if (_balances[msg.sender] > 0) {
            // Get the previous accounting balance
            uint256 prevBalancesAccounting = _balancesAccounting[msg.sender];
            // Get the new multiplier
            uint256 accTotalMultiplier = getTotalMultiplier(msg.sender);
            // Calculate new accounting  balance
            uint256 newBalancesAccounting = _balances[msg.sender]
                .mul(accTotalMultiplier)
                .div(1e18)
                .sub(_balances[msg.sender]);
            // Set the accounting balance
            _balancesAccounting[msg.sender] = newBalancesAccounting;
            // Get the difference for adjusting the total accounting balance
            uint256 diffBalancesAccounting = newBalancesAccounting.sub(
                prevBalancesAccounting
            );
            // Adjust the global accounting balance.
            _totalSupplyAccounting = _totalSupplyAccounting.add(
                diffBalancesAccounting
            );
        }

        emit Boost(level);
    }

    // Returns the multiplier for user.
    function getTotalMultiplier(address account) public view returns (uint256) {
        uint256 zzzMultiplier = multiplier.getPermanentMultiplier(account);
        uint256 boostMultiplier;
        if (boostLevel[account] == 1) {
            boostMultiplier = boostLevelOneBonus;
        } else if (boostLevel[account] == 2) {
            boostMultiplier = boostLevelTwoBonus;
        } else if (boostLevel[account] == 3) {
            boostMultiplier = boostLevelThreeBonus;
        } else if (boostLevel[account] == 4) {
            boostMultiplier = boostLevelFourBonus;
        } else if (boostLevel[account] == 5) {
            boostMultiplier = boostLevelFiveBonus;
        } else if (boostLevel[account] == 6) {
            boostMultiplier = boostLevelSixBonus;
        }
        return zzzMultiplier.add(boostMultiplier).add(1 * 10**18);
    }

    // Ejects any remaining tokens from the pool.
    // Callable only after the pool has started and the pools reward distribution period has finished.
    function eject() external onlyOwner {
        require(
            startTime < block.timestamp && block.timestamp >= periodFinish,
            "Cannot eject before period finishes or pool has started"
        );
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
        lastUpdateTime = lastTimeRewardApplicable();
    }

    function updateReward(address account) internal {
        updateRewardPerTokenStored();
        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }

    function changeBoostLevels(
        uint256 _boostLevelOneCost,
        uint256 _boostLevelTwoCost,
        uint256 _boostLevelThreeCost,
        uint256 _boostLevelFourCost,
        uint256 _boostLevelFiveCost,
        uint256 _boostLevelSixCost,
        uint256 _boostLevelOneBonus,
        uint256 _boostLevelTwoBonus,
        uint256 _boostLevelThreeBonus,
        uint256 _boostLevelFourBonus,
        uint256 _boostLevelFiveBonus,
        uint256 _boostLevelSixBonus
    ) public onlyOwner {
        boostLevelOneCost = _boostLevelOneCost;
        boostLevelTwoCost = _boostLevelTwoCost;
        boostLevelThreeCost = _boostLevelThreeCost;
        boostLevelFourCost = _boostLevelFourCost;
        boostLevelFiveCost = _boostLevelFiveCost;
        boostLevelSixCost = _boostLevelSixCost;

        boostLevelOneBonus = _boostLevelOneBonus;
        boostLevelTwoBonus = _boostLevelTwoBonus;
        boostLevelThreeBonus = _boostLevelThreeBonus;
        boostLevelFourBonus = _boostLevelFourBonus;
        boostLevelFiveBonus = _boostLevelFiveBonus;
        boostLevelSixBonus = _boostLevelSixBonus;
    }

    function calculateCycle(
        uint256 _deployedTime,
        uint256 _currentTime,
        uint256 _duration
    ) public pure returns (uint256) {
        uint256 cycles = (_currentTime.sub(_deployedTime)).div(_duration);
        return cycles;
    }
}
