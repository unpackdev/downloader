// SPDX-License-Identifier: MIT
/**
* The Mercury Staking Contract
*
* Features and assumptions:
* - Users stake token A and receive token B. These can be same or different tokens.
* - APY is configurable with rewardNumerator/rewardDenominator -- with 1 and 1 it's 100%, which means
    you stake 10 000 PROPEL, you get 10 000 PROPEL as rewards during the next year
* - Each stake is guaranteed the reward in 365 days, after which they can still get new rewards if
*   there is reward money left in the contract. If the reward cannot be guaranteed, the stake will not be accepted.
* - Each stake is locked for 365 days, after which it can be unstaked or left in the contract
*/
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";

contract MercuryStaking is ReentrancyGuard, Ownable {
    event Staked(
        address indexed user,
        uint256 amount
    );

    event Unstaked(
        address indexed user,
        uint256 amount
    );

    event RewardPaid(
        address indexed user,
        uint256 amount
    );

    event EmergencyWithdrawalInitiated();

    struct Stake {
        uint256 amount;
        uint256 timestamp;
    }

    struct UserStakingData {
        uint256 amountStaked;
        uint256 guaranteedReward;
        uint256 storedReward;
        uint256 storedRewardUpdatedOn;
        uint256 firstActiveStakeIndex; // for gas optimization if many stakes
        Stake[] stakes;
    }

    uint256 public constant lockedPeriod = 365 days;
    uint256 public constant yieldPeriod = 365 days;

    IERC20 public stakingToken;
    IERC20 public rewardToken;
    bool internal _stakingTokenIsRewardToken;
    uint256 public rewardNumerator;
    uint256 public rewardDenominator;

    uint256 public minStakeAmount = 10_000 ether; // should be at least 1
    bool public emergencyWithdrawalInProgress = false;
    bool public paused = false;

    mapping(address => UserStakingData) stakingDataByUser;

    uint256 public totalAmountStaked = 0;
    uint256 public totalGuaranteedReward = 0;
    uint256 public totalStoredReward = 0;

    constructor(
        address _stakingToken,
        address _rewardToken,
        uint256 _rewardNumerator,
        uint256 _rewardDenominator
    )
    Ownable()
    {
        require(_rewardNumerator != 0, "Reward numerator cannot be 0");  // would mean zero reward
        require(_rewardDenominator != 0, "Reward denominator cannot be 0");  // would mean division by zero

        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        _stakingTokenIsRewardToken = _stakingToken == _rewardToken;

        rewardNumerator = _rewardNumerator;
        rewardDenominator = _rewardDenominator;
    }

    // PUBLIC USER API
    // ===============

    function stake(
        uint256 amount
    )
    public
    virtual
    nonReentrant
    {
        require(!paused, "Staking is temporarily paused, no new stakes accepted");
        require(!emergencyWithdrawalInProgress, "Emergency withdrawal in progress, no new stakes accepted");
        require(amount >= minStakeAmount, "Minimum stake amount not met");
        // This needs to be checked before accepting the stake, in case stakedToken and rewardToken are the same
        require(
            availableToStake() >= amount,
            "Not enough rewards left to accept new stakes for given amount"
        );
        require(
            stakingToken.transferFrom(msg.sender, address(this), amount),
            "Cannot transfer balance"
        );

        UserStakingData storage userData = stakingDataByUser[msg.sender];

        // Update stored reward, in case the user has already staked
        _updateStoredReward(userData);

        userData.stakes.push(Stake({
            amount: amount,
            timestamp: block.timestamp
        }));
        userData.amountStaked += amount;
        totalAmountStaked += amount;

        uint256 rewardAmount = amount * rewardNumerator / rewardDenominator;
        require(rewardAmount > 0, "Zero reward amount");

        userData.guaranteedReward += rewardAmount;
        totalGuaranteedReward += rewardAmount;
        userData.storedRewardUpdatedOn = block.timestamp;  // may waste some gas, but would rather be safe than sorry

        emit Staked(
            msg.sender,
            amount
        );
    }

    function claimReward()
    public
    virtual
    nonReentrant
    {
        _rewardUser(msg.sender);
    }

    function unstake(
        uint256 amount
    )
    public
    virtual
    nonReentrant
    {
        _unstakeUser(msg.sender, amount);
    }

    function exit()
    public
    virtual
    nonReentrant
    {
        UserStakingData storage userData = stakingDataByUser[msg.sender];
        if (userData.amountStaked > 0) {
            _unstakeUser(msg.sender, userData.amountStaked);
        }
        _rewardUser(msg.sender);
        delete stakingDataByUser[msg.sender];
    }

    // PUBLIC VIEWS AND UTILITIES
    // ==========================

    function availableToStake()
    public
    view
    returns (uint256 stakeable)
    {
        stakeable = rewardToken.balanceOf(address(this)) - totalLockedReward();
        if (_stakingTokenIsRewardToken) {
            stakeable -= totalAmountStaked;
        }
        stakeable = stakeable * rewardDenominator / rewardNumerator;
    }

    function availableToReward()
    public
    view
    returns (uint256 rewardable)
    {
        rewardable = rewardToken.balanceOf(address(this)) - totalLockedReward();
        if (_stakingTokenIsRewardToken) {
            rewardable -= totalAmountStaked;
        }
    }

    function availableToStakeOrReward()
    public
    view
    returns (uint256 stakeable)
    {
        // NOTE: this is a misnomer if rewardNumerator/rewardDenominator != 1, thus it's deprecated and only for
        // backwards compatibility
        stakeable = availableToStake();
    }

    function totalLockedReward()
    public
    view
    returns (uint256 locked)
    {
        locked = totalStoredReward + totalGuaranteedReward;
    }

    function rewardClaimable(
        address user
    )
    public
    view
    returns (uint256 reward)
    {
        UserStakingData storage userData = stakingDataByUser[user];
        reward = userData.storedReward;
        reward += _calculateStoredRewardToAdd(userData);
    }

    function staked(
        address user
    )
    public
    view
    returns (uint256 amount)
    {
        UserStakingData storage userData = stakingDataByUser[user];
        return userData.amountStaked;
    }

    // OWNER API
    // =========

    function payRewardToUser(
        address user
    )
    public
    virtual
    onlyOwner
    nonReentrant
    {
        _rewardUser(user);
    }

    function withdrawTokens(
        address token,
        uint256 amount
    )
    public
    virtual
    onlyOwner
    nonReentrant
    {
        if (token == address(rewardToken)) {
            require(amount <= availableToReward(), "Can only withdraw up to balance minus locked amount");
        } else if (token == address(stakingToken)) {
            uint256 maxAmount = stakingToken.balanceOf(address(this)) - totalAmountStaked;
            require(amount <= maxAmount, "Cannot withdraw staked tokens");
        }
        IERC20(token).transfer(msg.sender, amount);
    }

    function setMinStakeAmount(
        uint256 newMinStakeAmount
    )
    public
    virtual
    onlyOwner
    nonReentrant
    {
        require(newMinStakeAmount > 1, "Minimum stake amount must be at least 1");
        minStakeAmount = newMinStakeAmount;
    }

    function setPaused(
        bool newPaused
    )
    public
    virtual
    onlyOwner
    nonReentrant
    {
        paused = newPaused;
    }

    function initiateEmergencyWithdrawal()
    public
    virtual
    onlyOwner
    nonReentrant
    {
        require(!emergencyWithdrawalInProgress, "Emergency withdrawal already in progress");
        emergencyWithdrawalInProgress = true;
        emit EmergencyWithdrawalInitiated();
    }

    function forceExitUser(
        address user
    )
    public
    virtual
    onlyOwner
    nonReentrant
    {
        // NOTE: this pays all of guaranteed reward to the user, even ahead of schedule with humongous APY!
        require(emergencyWithdrawalInProgress, "Emergency withdrawal not in progress");
        UserStakingData storage userData = stakingDataByUser[user];
        if (userData.amountStaked > 0) {
            totalAmountStaked -= userData.amountStaked;
            stakingToken.transfer(user, userData.amountStaked);
            emit Unstaked(
                user,
                userData.amountStaked
            );
            //userData.amountStaked = 0;
        }
        uint256 userReward = userData.storedReward + userData.guaranteedReward;
        if (userReward > 0) {
            rewardToken.transfer(user, userReward);
            totalStoredReward -= userData.storedReward;
            totalGuaranteedReward -= userData.guaranteedReward;
            emit RewardPaid(
                user,
                userReward
            );
            //userData.storedReward = 0;
            //userData.guaranteedReward = 0;
        }
        // delete the whole thing to set everything as 0 and to save on gas
        delete stakingDataByUser[user];
    }

    // INTERNAL API
    // ============

    function _rewardUser(
        address user
    )
    internal
    {
        UserStakingData storage userData = stakingDataByUser[user];
        _updateStoredReward(userData);

        uint256 reward = userData.storedReward;
        if (reward == 0) {
            return;
        }

        userData.storedReward = 0;
        totalStoredReward -= reward;

        require(
            rewardToken.transfer(user, reward),
            "Sending reward failed"
        );

        emit RewardPaid(
            user,
            reward
        );
    }

    function _unstakeUser(
        address user,
        uint256 amount
    )
    private
    {
        require(amount > 0, "Cannot unstake zero amount");

        UserStakingData storage userData = stakingDataByUser[user];
        _updateStoredReward(userData);

        uint256 amountLeft = amount;

        uint256 i = userData.firstActiveStakeIndex;
        for (; i < userData.stakes.length; i++) {
            if (userData.stakes[i].amount == 0) {
                continue;
            }

            require(
                userData.stakes[i].timestamp <= block.timestamp - lockedPeriod,
                "Unstaking is only allowed after the locked period has expired"
            );
            if (userData.stakes[i].amount > amountLeft) {
                userData.stakes[i].amount -= amountLeft;
                amountLeft = 0;
                break;
            } else {
                // stake amount equal to or smaller than amountLeft
                amountLeft -= userData.stakes[i].amount;
                userData.stakes[i].amount = 0;
                delete userData.stakes[i];  // this should be safe and saves a little bit of gas, but also leaves a gap in the array
            }
        }

        require(
            amountLeft == 0,
            "Not enough staked balance left to unstake all of wanted amount"
        );

        userData.firstActiveStakeIndex = i;
        userData.amountStaked -= amount;
        totalAmountStaked -= amount;

        // We need to make sure the user is left with no guaranteed reward if they have unstaked everything
        // -- in that case, just add to stored reward.
        if (userData.guaranteedReward > 0 && i == userData.stakes.length) {
            userData.storedReward += userData.guaranteedReward;
            totalStoredReward += userData.guaranteedReward;

            totalGuaranteedReward -= userData.guaranteedReward;
            userData.guaranteedReward = 0;

            userData.storedRewardUpdatedOn = block.timestamp;
        }

        require(
            stakingToken.transfer(msg.sender, amount),
            "Transferring staked token back to sender failed"
        );

        emit Unstaked(
            msg.sender,
            amount
        );
    }

    function _updateStoredReward(
        UserStakingData storage userData
    )
    internal
    {
        uint256 addedStoredReward = _calculateStoredRewardToAdd(userData);
        if (addedStoredReward != 0) {
            userData.storedReward += addedStoredReward;
            totalStoredReward += addedStoredReward;
            if (addedStoredReward > userData.guaranteedReward) {
                totalGuaranteedReward -= userData.guaranteedReward;
                userData.guaranteedReward = 0;
            } else {
                userData.guaranteedReward -= addedStoredReward;
                totalGuaranteedReward -= addedStoredReward;
            }
            userData.storedRewardUpdatedOn = block.timestamp;
        }
    }

    function _calculateStoredRewardToAdd(
        UserStakingData storage userData
    )
    internal
    view
    returns (uint256 storedRewardToAdd) {
        if (userData.storedRewardUpdatedOn == 0 || userData.storedRewardUpdatedOn == block.timestamp) {
            // safety check -- don't want to accidentally multiply everything by the unix epoch instead of time passed
            return 0;
        }
        uint256 timePassedFromLastUpdate = block.timestamp - userData.storedRewardUpdatedOn;
        storedRewardToAdd = (userData.amountStaked * rewardNumerator * timePassedFromLastUpdate / rewardDenominator) / yieldPeriod;

        // We can pay out more than guaranteed, but only if we have enough non-locked funds for it
        if (storedRewardToAdd > userData.guaranteedReward) {
            uint256 excess = storedRewardToAdd - userData.guaranteedReward;
            uint256 available = availableToReward();
            if (excess > available) {
                storedRewardToAdd = storedRewardToAdd - excess + available;
            }
        }
    }
}