// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IERC20.sol";
import "./Ownable.sol";

contract PlanetRewards is Ownable {
    bool public stakingEnabled;
    address public immutable PLANET;
    uint256 public rewardRate = 10000;
    uint256 public firstStakeAmount = 1_000_000 ether;
    uint256 public minStake = 100_000 ether;
    uint256 public cooldown = 1 days;
    uint256 public maxStakeDurationWithoutNewEntry = 52 weeks;
    uint256 public minStakeDuration;
    uint256 public globalTotalStaked;
    uint256 public totalUniqueStakers;

    mapping(address => Account) public account;

    address[] public lastWinners;

    struct Account {
        uint256 lastStakedAt;
        uint256 totalStaked;
        uint256 creditedPoints;
    }

    event Stake(address indexed staker, uint256 amount, uint256 totalCreditedPoints, uint256 timestamp);
    event Unstake(address indexed staker, uint256 amount, uint256 timestamp);
    event StakingEnabled(bool enabled);
    event ResetWinner(address winner);
    event SetMinStake(uint256 value);
    event SetFirstStakeAmount(uint256 value);
    event SetMinStakeDuration(uint256 value);
    event SetRewardRate(uint256 value);
    event SetMinStakeDurationWithoutNewEntry(uint256 value);
    event SetCooldown(uint256 value);

    error InvalidStakingAmount();
    error NoStakedTokens();
    error StakingNotEnabled();
    error UnstakingNotPermitted();
    error ZeroValue();

    constructor(address planet) {
        PLANET = planet;
    }

    function stake(uint256 amount) public {
        if (!stakingEnabled) revert StakingNotEnabled();
        if (amount % minStake != 0) revert InvalidStakingAmount();

        IERC20(PLANET).transferFrom(msg.sender, address(this), amount);

        uint256 stakedBefore = account[msg.sender].totalStaked;

        if (stakedBefore == 0) {
            if (amount < firstStakeAmount) revert InvalidStakingAmount();
            totalUniqueStakers++;
        }
        
        globalTotalStaked += amount;

        uint256 points = totalPoints(msg.sender);

        account[msg.sender] = Account(
            {
                lastStakedAt: block.timestamp,
                totalStaked: stakedBefore + amount,
                creditedPoints: points
            }
        );
        
        emit Stake(msg.sender, amount, points, block.timestamp);
    }

    function unstake() public {
        uint256 stakedTokens = account[msg.sender].totalStaked;

        if (stakedTokens == 0) revert NoStakedTokens();
        if (block.timestamp - account[msg.sender].lastStakedAt < minStakeDuration) {
            revert UnstakingNotPermitted();
        }

        totalUniqueStakers--;
        globalTotalStaked -= stakedTokens;

        account[msg.sender].creditedPoints = totalPoints(msg.sender);
        
        delete account[msg.sender].lastStakedAt;
        delete account[msg.sender].totalStaked;

        IERC20(PLANET).transfer(msg.sender, stakedTokens);

        emit Unstake(msg.sender, stakedTokens, block.timestamp);
    }

    function totalPoints(address wallet) public view returns (uint256) {
        uint256 timePassed = block.timestamp - account[wallet].lastStakedAt;
        uint256 accumulated;
        if (timePassed != block.timestamp) {
            if (timePassed >= maxStakeDurationWithoutNewEntry) {
                return 0;
            }
            accumulated = ((timePassed / cooldown) * account[wallet].totalStaked) / rewardRate;
        }
        return account[wallet].creditedPoints + accumulated;
    }

    /* -------------------------------------------------------------------------- */
    /*                         OWNER RESTRICTED FUNCTIONS                         */
    /* -------------------------------------------------------------------------- */

    function resetWinners(address[] calldata winners) external onlyOwner {
        uint256 length = winners.length;
        for (uint256 i = 0; i < length; i++) {
            account[winners[i]].lastStakedAt = block.timestamp;
            delete account[winners[i]].creditedPoints;
            emit ResetWinner(winners[i]);
        }
        lastWinners = winners;
    }

    function addToLastWinners(address[] calldata winners) external onlyOwner {
        uint256 length = winners.length;
        for (uint256 i = 0; i < length; i++) {
            account[winners[i]].lastStakedAt = block.timestamp;
            delete account[winners[i]].creditedPoints;
            lastWinners.push(winners[i]);
            emit ResetWinner(winners[i]);
        }
    }

    function setMinStake(uint256 newValue) external onlyOwner {
        if (newValue == 0) revert ZeroValue();
        minStake = newValue;
        emit SetMinStake(newValue);
    }

    function setFirstStakeAmount(uint256 newValue) external onlyOwner {
        if (newValue == 0) revert ZeroValue();
        firstStakeAmount = newValue;
        emit SetFirstStakeAmount(newValue);
    }

    function setMinStakeDuration(uint256 newValue) external onlyOwner {
        minStakeDuration = newValue;
        emit SetMinStakeDuration(newValue);
    }

    function setRewardRate(uint256 newValue) external onlyOwner {
        if (newValue == 0) revert ZeroValue();
        rewardRate = newValue;
        emit SetRewardRate(newValue);
    }

    function setStakingEnabled(bool newValue) external onlyOwner {
        stakingEnabled = newValue;
        emit StakingEnabled(newValue);
    }

    function setMaxStakePeriodWithoutNewEntry(uint256 newValue) external onlyOwner {
        maxStakeDurationWithoutNewEntry = newValue;
        emit SetMinStakeDurationWithoutNewEntry(newValue);
    }

    function setCooldown(uint256 newValue) external onlyOwner {
        if (newValue == 0) revert ZeroValue();
        cooldown = newValue;
        emit SetCooldown(newValue);
    }
}
