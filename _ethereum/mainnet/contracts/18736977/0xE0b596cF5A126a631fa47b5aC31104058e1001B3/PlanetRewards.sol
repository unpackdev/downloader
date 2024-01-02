// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IERC20.sol";
import "./Ownable.sol";
import "./IPlanetRewards.sol";

contract PlanetRewards is IPlanetRewards, Ownable {
    address public immutable PLANET;

    bool public stakingEnabled;
    uint256 public rewardRate = 100;
    uint256 public minStake = 100_000 ether;
    uint256 public cooldown = 1 days;
    uint256 public maxStakeDurationWithoutNewEntry = 52 weeks;
    uint256 public minStakeDuration;
    uint256 public globalTotalStaked;
    uint256 public totalUniqueStakers;

    mapping(address => Account) public account;

    address[] public lastWinners;

    constructor(address planet) {
        PLANET = planet;
    }

    function stake(uint256 amount) public {
        if (!stakingEnabled) revert StakingNotEnabled();
        if (amount < minStake) revert InvalidStakingAmount();

        IERC20(PLANET).transferFrom(msg.sender, address(this), amount);

        uint256 stakedBefore = account[msg.sender].totalStaked;
        bool isNewStaker = stakedBefore == 0;

        if (isNewStaker) totalUniqueStakers++;
        globalTotalStaked += amount;

        uint256 points = isNewStaker ? 0 : totalPoints(msg.sender);

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

        IERC20(PLANET).transfer(msg.sender, stakedTokens);

        totalUniqueStakers--;
        globalTotalStaked -= stakedTokens;
        
        delete account[msg.sender];

        emit Unstake(msg.sender, stakedTokens, block.timestamp);
    }

    function totalPoints(address wallet) public view returns (uint256) {
        uint256 timePassed = block.timestamp - account[wallet].lastStakedAt;

        if (
            timePassed == block.timestamp ||
            timePassed >= maxStakeDurationWithoutNewEntry)
        {
            return 0;
        }

        uint256 accumulated =
            ((timePassed / cooldown) * account[wallet].totalStaked) / rewardRate;

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

    function setMinStake(uint256 newValue) external onlyOwner {
        if (newValue == 0) revert ZeroValue();
        minStake = newValue;
    }

    function setMinStakeDuration(uint256 newValue) external onlyOwner {
        minStakeDuration = newValue;
    }

    function setRewardRate(uint256 newValue) external onlyOwner {
        if (newValue == 0) revert ZeroValue();
        rewardRate = newValue;
    }

    function setStakingEnabled(bool newValue) external onlyOwner {
        stakingEnabled = newValue;
        emit StakingEnabled(newValue);
    }

    function setMaxStakePeriodWithoutNewEntry(uint256 newValue) external onlyOwner {
        maxStakeDurationWithoutNewEntry = newValue;
    }

    function setCooldown(uint256 newValue) external onlyOwner {
        if (newValue == 0) revert ZeroValue();
        cooldown = newValue;
    }
}
