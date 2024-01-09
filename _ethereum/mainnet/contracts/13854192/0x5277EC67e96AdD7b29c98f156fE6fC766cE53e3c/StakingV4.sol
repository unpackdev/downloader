//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./AccessLevel.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";

contract StakingV4 is AccessLevel {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IERC20Upgradeable public stakingToken;

    event Stake(uint256 stakeId, address staker);   
    event Unstake(uint256 stakeId, address unstaker);

    struct StakingInfo{
        address owner;
        uint id;
        uint timeToUnlock;
        uint stakingTime;
        uint tokensStaked;
        uint tokensStakedWithBonus;
    }

    uint public maxLoss;
    bool public stakingEnabled;
    uint public rewardRate; // 1.929 tokens per sec = 166666 tokens per day
    uint private constant DIVISOR = 1e11;
    uint public lastUpdateTime;
    uint public rewardPerTokenStored;
    uint public minClaimPeriod;
    address public communityAddress;
    uint public uniqueAddressesStaked;
    uint public totalTokensStaked;

    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;
    mapping(uint => uint) public bonusTokenMultiplier;
    mapping(address => mapping(uint => StakingInfo)) public stakingInfoForAddress;
    mapping(address => uint) public tokensStakedByAddress;
    mapping(address => uint) public tokensStakedWithBonusByAddress;

    uint public totalTokensStakedWithBonusTokens;
    mapping(address => uint) public balances;
    mapping(address => uint) public lastClaimedTimestamp;
    mapping(address => uint) public stakingNonce;

    /** Initializes the staking contract
    @param tokenAddress_ the token address that will be staked
    @param owner_ the address of the contract owner
    @param communityAddress_ the address the community tokens will be gathering
     */
    function initialize(address tokenAddress_, address owner_, address communityAddress_, uint minClaimPeriod_, uint rewardRate_) initializer external {
        __AccessLevel_init(owner_);
        stakingToken = IERC20Upgradeable(tokenAddress_);
        stakingEnabled = true;
        communityAddress = communityAddress_;
        minClaimPeriod = minClaimPeriod_;
        rewardRate = rewardRate_;
    }

    /** Computes the reward per token
    */
    function rewardPerToken() public view returns (uint) {
        if (totalTokensStakedWithBonusTokens == 0) {
            return 0;
        }
        return
            rewardPerTokenStored +
            (((block.timestamp - lastUpdateTime) * rewardRate * 1e18) / totalTokensStakedWithBonusTokens);
    }

    /** Computes the earned amount thus far by the address
    @param account_ account to get the earned ammount for
     */
    function earned(address account_) public view returns (uint) {
        return
            ((balances[account_] *
                (rewardPerToken() - userRewardPerTokenPaid[account_])) / 1e18) +
            rewards[account_];
    }

    /** modifier that updates and computes the correct internal variables
    @param account_ the account called for
     */
    modifier updateReward(address account_) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;

        rewards[account_] = earned(account_);
        userRewardPerTokenPaid[account_] = rewardPerTokenStored;
        _;
    }

    /** Staking function
    @param amount_ the amount to stake
    @param lockTime_ the lock time to lock the stake for
     */
    function stake(uint amount_, uint lockTime_) external updateReward(msg.sender) {
        require(stakingEnabled , "STAKING_DISABLED");
        require(amount_ > 0, "CANNOT_STAKE_0");
        require(bonusTokenMultiplier[lockTime_] > 0, "LOCK_TIME_ERROR");

        if(stakingNonce[msg.sender] == 0){
            uniqueAddressesStaked++;
        }
        uint tokensWithBonus = amount_ * bonusTokenMultiplier[lockTime_] / DIVISOR;

        totalTokensStaked += amount_;
        totalTokensStakedWithBonusTokens += tokensWithBonus;
        balances[msg.sender] += tokensWithBonus;
        tokensStakedByAddress[msg.sender] += amount_;
        tokensStakedWithBonusByAddress[msg.sender] += tokensWithBonus;
        lastClaimedTimestamp[msg.sender] = block.timestamp;

        StakingInfo storage data = stakingInfoForAddress[msg.sender][stakingNonce[msg.sender]];
        data.owner = msg.sender;
        data.stakingTime = block.timestamp;
        data.tokensStaked = amount_;
        data.timeToUnlock = block.timestamp + lockTime_;
        data.tokensStakedWithBonus = tokensWithBonus;
        data.id = stakingNonce[msg.sender];

        emit Stake(stakingNonce[msg.sender], msg.sender);
        stakingNonce[msg.sender]++;

        stakingToken.safeTransferFrom(msg.sender, address(this), amount_);
    }

    /** Unstake function
    @param stakeId_ the stake id to unstake
     */
    function unstake(uint stakeId_) external updateReward(msg.sender) {
        getRewardInternal();
        StakingInfo storage info = stakingInfoForAddress[msg.sender][stakeId_];

        totalTokensStaked -= info.tokensStaked;
        totalTokensStakedWithBonusTokens -= info.tokensStakedWithBonus;
        balances[msg.sender] -= info.tokensStakedWithBonus;
        tokensStakedByAddress[msg.sender] -= info.tokensStaked;
        tokensStakedWithBonusByAddress[msg.sender] -= info.tokensStakedWithBonus;

        uint tokensLost = 0;
        uint tokensTotal = info.tokensStaked;
        
        if(info.timeToUnlock > block.timestamp) {
            uint maxTime = info.timeToUnlock - info.stakingTime;
            uint lossPercentage = maxLoss - (block.timestamp - info.stakingTime) * maxLoss / maxTime;
            tokensLost = lossPercentage * info.tokensStaked / DIVISOR;
            stakingToken.safeTransfer(communityAddress, tokensLost);
        }

        delete stakingInfoForAddress[msg.sender][stakeId_];
        emit Unstake(stakeId_, msg.sender);

        stakingToken.safeTransfer(msg.sender, tokensTotal - tokensLost);
    }

    /** The function called to get the reward for all the user stakes
     */
    function getReward() external updateReward(msg.sender) {
        require(lastClaimedTimestamp[msg.sender] + minClaimPeriod <= block.timestamp,
         "Cannot claim Rewards Yet");
        getRewardInternal();
    }

    /** The function called to get the reward for all the user stakes
    This function does not check for min claimPeriod
     */
    function getRewardInternal() internal {
        lastClaimedTimestamp[msg.sender] = block.timestamp;
        uint reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        stakingToken.safeTransfer(msg.sender, reward);
    }

    /** 
    @dev Sets the bonus multipliers and the allowed locking durations
    @param durations_ an array of the allowed staking durations
    @param mutiplier_ the multiplier dor all staking durations
     */
    function setBonusMultiplier(uint[] calldata durations_, uint[] calldata mutiplier_) 
    external onlyRole(DEFAULT_ADMIN_ROLE) {
        for(uint256 i = 0; i < durations_.length; i++) {
            require(mutiplier_[i] >= DIVISOR, "Invalid multiplier");
            bonusTokenMultiplier[durations_[i]] = mutiplier_[i];
        }
    }

        /** 
    @dev Sets the staking enabled flag
    @param stakingEnabled_ weather or not staking should be enabled
    */
    function setStakingEnabled(bool stakingEnabled_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        stakingEnabled = stakingEnabled_;
    }

    /** 
    @dev Sets the maximum possible loss
    @param maxLoss_ the max loss possibe for an early unstake
    */
    function setMaxLoss(uint maxLoss_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(maxLoss < DIVISOR, "maxLoss should be less that divisor");
        maxLoss = maxLoss_;
    }

    /** 
    @dev Sets the new reward rate
    @param rewardRate_ the reward rate to set up
    */
    function setRewardRate(uint rewardRate_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(rewardRate_ > 0, "Cannot have reward Rate 0");
        rewardRate = rewardRate_;
    }

    /** 
    @dev Sets the new minimum claim period
    @param minClaimPeriod_ the period limit for claiming rewards
    */
    function setMinClaimPeriod(uint minClaimPeriod_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        minClaimPeriod = minClaimPeriod_;
    }

    /**
    @dev Returns all the user stakes
    @param userAddress_ returns all the user stakes
     */
    function getAllAddressStakes(address userAddress_) public view returns(StakingInfo[] memory)
    {
        StakingInfo[] memory stakings = new StakingInfo[](stakingNonce[userAddress_]);
        for (uint i = 0; i < stakingNonce[userAddress_]; i++) {
            StakingInfo memory staking = stakingInfoForAddress[userAddress_][i];
            if(staking.tokensStaked > 0){
                stakings[i] = staking;
            }
        }
        return stakings;
    }
}