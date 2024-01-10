//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessLevel.sol";
import "./UUPSUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";

contract StakePIF is UUPSUpgradeable, AccessLevel,ReentrancyGuardUpgradeable {
    
    using SafeERC20Upgradeable for IERC20Upgradeable;
    
    IERC20Upgradeable public stakingToken;
    IERC20Upgradeable public rewardToken;
 
    event Unstake(uint256 stakeId, address unstaker);
    event Stake(uint256 stakeId, address staker);
    event SetStakingEnabled(bool stakingEnabled, address sender);
    event SetMaxLoss(uint maxLoss, address sender);   
    event SetMaxStakingWeeks(uint maxStakingWeeks, address sender);   
    event SetRewardRate(uint rewardRate, address sender);   
    event SetMinClaimPeriod(uint rewardRate, address sender);
    event SetCommunityAddress(address communityAddress, address sender);

    struct StakingInfo{
        address owner;
        uint id;
        uint timeToUnlock;
        uint stakingTime;
        uint tokensStaked;
        uint tokensStakedWithBonus;
    }

    address public communityAddress;
    bool public stakingEnabled;
    uint private constant DIVISOR = 1e11;
    uint private constant DECIMAL = 1e18;
    uint private constant WEEK_PER_YEAR = 52;
    uint public maxLoss;
    uint public maxStakingWeeks;
    uint public rewardRate; 
    uint public lastUpdateTime;
    uint public rewardPerTokenStored;
    uint public minClaimPeriod;
    uint public uniqueAddressesStaked;
    uint public totalTokensStaked;
    uint public totalRewardsClaimed;

    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;
    mapping(address => mapping(uint => StakingInfo)) public stakingInfoForAddress;
    mapping(address => uint) public tokensStakedByAddress;
    mapping(address => uint) public tokensStakedWithBonusByAddress;
    mapping(address => uint) public totalRewardsClaimedByAddress;

    uint public totalTokensStakedWithBonusTokens;
    mapping(address => uint) public balances;
    mapping(address => uint) public lastClaimedTimestamp;
    mapping(address => uint) public stakingNonce;


    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    
    /** Initializes the staking contract
    @param tokenAddress_ the token address that will be staked
    @param rewardToken_ the token address that will be rewarded
    @param owner_ the address of the contract owner
    @param communityAddress_ the address the community tokens will be gathering
    @param minClaimPeriod_ the period limit for claiming rewards
    @param rewardRate_ the reward rate to set up
    @param maxLoss_ the max loss possibe for an early unstake
    @param maxStakingWeeks_ the max locked staking period in weeks
    */

    // we add change community address 
    function initialize(address tokenAddress_, address rewardToken_, address owner_, address communityAddress_, uint minClaimPeriod_, uint rewardRate_, uint maxLoss_, uint maxStakingWeeks_) initializer external {
        require(tokenAddress_ != address(0),"INVALID_TOKEN_ADDRESS");
        require(rewardToken_ != address(0),"INVALID_TOKEN_ADDRESS");
        require(owner_ != address(0),"INVALID_OWNER_ADDRESS");
        require(communityAddress_ != address(0),"INVALID_COMMUNITY_ADDRESS");
        require(minClaimPeriod_ > 0,"INVALID_MIN_CLAIM_PERIOD");
        require(rewardRate_ > 0,"INVALID_REWARD_RATE");
        require(maxLoss_ > 0,"INVALID_MAX_LOSS");
        require(maxLoss_ < DIVISOR, "INVALID_MAX_LOSS");
        require(maxStakingWeeks_ > 0,"INVALID_MAX_STAKING_WEEKS");

        __AccessLevel_init(owner_);
        __ReentrancyGuard_init();
        stakingToken = IERC20Upgradeable(tokenAddress_);
        rewardToken = IERC20Upgradeable(rewardToken_);
        stakingEnabled = true;
        communityAddress = communityAddress_;
        minClaimPeriod = minClaimPeriod_;
        rewardRate = rewardRate_;
        maxLoss = maxLoss_;
        maxStakingWeeks = maxStakingWeeks_;
    }

    /** Computes the reward per token
    */
    function rewardPerToken() public view returns (uint) {
        if (totalTokensStakedWithBonusTokens == 0) {
            return 0;
        }

        return
            rewardPerTokenStored +
            (((block.timestamp - lastUpdateTime) * rewardRate * DECIMAL) / totalTokensStakedWithBonusTokens);
    }

    /** Computes the earned amount thus far by the address
    @param account_ account to get the earned ammount for
    */
    function earned(address account_) public view returns (uint) {
        return
            ((balances[account_] *
                (rewardPerToken() - userRewardPerTokenPaid[account_])) / DECIMAL) +
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
    @param lockWeek_ the lock week to lock the stake for
    */
    function stake(uint amount_, uint lockWeek_) external nonReentrant() updateReward(msg.sender) {
        require(stakingEnabled , "STAKING_DISABLED");
        require(amount_ > 0, "CANNOT_STAKE_0");
        require(lockWeek_ <= maxStakingWeeks, "LOCK_TIME_ERROR");

        if(stakingNonce[msg.sender] == 0){
            uniqueAddressesStaked++;
        }

        stakingNonce[msg.sender]++;
        uint bonusTokenWeightage = DIVISOR + DIVISOR * lockWeek_ / WEEK_PER_YEAR;
        if (lockWeek_ > WEEK_PER_YEAR) {
            bonusTokenWeightage += DIVISOR * (lockWeek_ - WEEK_PER_YEAR) / WEEK_PER_YEAR;
        }
        uint tokensWithBonus = amount_ * bonusTokenWeightage / DIVISOR;

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
        data.timeToUnlock = block.timestamp + lockWeek_ * 604800;
        data.tokensStakedWithBonus = tokensWithBonus;
        data.id = stakingNonce[msg.sender];

        emit Stake(stakingNonce[msg.sender], msg.sender);
       
        stakingToken.safeTransferFrom(msg.sender, address(this), amount_);
    
    }

    /** Unstake function
    @param stakeId_ the stake id to unstake
    */
    function unstake(uint stakeId_) external nonReentrant() updateReward(msg.sender) {
        getRewardInternal();
        StakingInfo storage info = stakingInfoForAddress[msg.sender][stakeId_];
        require(stakeId_ > 0 && info.id == stakeId_,"INVALID_STAKE_ID");
        
        totalTokensStaked -= info.tokensStaked;
        totalTokensStakedWithBonusTokens -= info.tokensStakedWithBonus;
        balances[msg.sender] -= info.tokensStakedWithBonus;
        tokensStakedByAddress[msg.sender] -= info.tokensStaked;
        tokensStakedWithBonusByAddress[msg.sender] -= info.tokensStakedWithBonus;

        if (balances[msg.sender] == 0) {
            userRewardPerTokenPaid[msg.sender] = 0;
        }

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
    function getReward() external nonReentrant() updateReward(msg.sender) {
        require(lastClaimedTimestamp[msg.sender] + minClaimPeriod <= block.timestamp,
         "CANNOT_CLAIM_REWARDS_YET");
        getRewardInternal();
    }

    /** The function called to get the reward for all the user stakes
    This function does not check for min claimPeriod
    */
    function getRewardInternal() internal {
        lastClaimedTimestamp[msg.sender] = block.timestamp;
        uint reward = rewards[msg.sender];
        require(rewardToken.balanceOf(address(this)) >= reward ,"BALANCE_NOT_ENOUGH");

        rewards[msg.sender] = 0;
        totalRewardsClaimed += reward;
        totalRewardsClaimedByAddress[msg.sender] += reward;
        rewardToken.safeTransfer(msg.sender, reward);
    }

    /** 
    @dev Sets the staking enabled flag
    @param stakingEnabled_ weather or not staking should be enabled
    */
    function setStakingEnabled(bool stakingEnabled_) external onlyRole(OPERATOR_ROLE) {
        stakingEnabled = stakingEnabled_;

        emit SetStakingEnabled(stakingEnabled_,msg.sender);
    }

    /** 
    @dev Sets the maximum possible loss
    @param maxLoss_ the max loss possibe for an early unstake
    */
    function setMaxLoss(uint maxLoss_) external onlyRole(OPERATOR_ROLE) {
        require(maxLoss_ > 0,"INVALID_MAX_LOSS");
        require(maxLoss_ < DIVISOR, "INVALID_MAX_LOSS");
        maxLoss = maxLoss_;

        emit SetMaxLoss(maxLoss_,msg.sender);
    }

    /** 
    @dev Sets the maximum locked staking period in weeks
    @param maxStakingWeeks_ the max locked staking period in weeks
    */
    function setMaxStakingWeeks(uint maxStakingWeeks_) external onlyRole(OPERATOR_ROLE) {
        require(maxStakingWeeks_ > 0,"INVALID_MAX_LOSS");
        maxStakingWeeks = maxStakingWeeks_;

        emit SetMaxStakingWeeks(maxStakingWeeks_,msg.sender);
    }

    /** 
    @dev Sets the new reward rate
    @param rewardRate_ the reward rate to set up
    */
    function setRewardRate(uint rewardRate_) external onlyRole(OPERATOR_ROLE) {
        require(rewardRate_ > 0, "INVALID_REWARD_RATE");
        rewardRate = rewardRate_;

        emit SetRewardRate(rewardRate_,msg.sender);
    }

    /** 
    @dev Sets the new minimum claim period
    @param minClaimPeriod_ the period limit for claiming rewards
    */
    function setMinClaimPeriod(uint minClaimPeriod_) external onlyRole(OPERATOR_ROLE) {
        require(minClaimPeriod_ > 0,"INVALID_MIN_CLAIM_PERIOD");
        minClaimPeriod = minClaimPeriod_;

        emit SetMinClaimPeriod(minClaimPeriod_,msg.sender);
    }

    /** 
    @dev Sets commuity address
    @param communityAddress_ the address the community tokens will be gathering
    */
    function setCommunityAddress_(address communityAddress_) external onlyRole(OPERATOR_ROLE) {
        communityAddress = communityAddress_;

        emit SetCommunityAddress(communityAddress,msg.sender);
    }

    /**
    @dev Returns all the user stakes
    @param userAddress_ returns all the user stakes
    */
    function getAllAddressStakes(address userAddress_) public view returns(StakingInfo[] memory)
    {
        StakingInfo[] memory stakings = new StakingInfo[](stakingNonce[userAddress_]);
        for (uint i = 0; i < stakingNonce[userAddress_]; i++) {
            StakingInfo memory staking = stakingInfoForAddress[userAddress_][i+1];
            if(staking.tokensStaked > 0){
                stakings[i] = staking;
            }
        }
        return stakings;
    }
}