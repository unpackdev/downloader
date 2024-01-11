//SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./SafeERC20.sol";
import "./Ownable.sol";

interface IWhitelist {
    function isWhitelisted(address account) external view returns (bool);
}

contract PhunTokenStakingUniswapV2 is Ownable {
    using SafeERC20 for IERC20;
    IERC20 public rewardToken;
    IERC20 public stakedToken;
    IWhitelist public whitelistContract;
    uint256 public totalSupply;
    uint256 public rewardRate;
    uint64 public periodFinish;
    uint64 public lastUpdateTime;
    uint128 public rewardPerTokenStored;
    bool public rewardsWithdrawn = false;
    uint256 private exitPercent;
    uint256 public exitPercentSet;
    address public treasury;
    mapping (address => bool) public whitelist;
    mapping(address => uint256) private _balances;
    struct UserRewards {
        uint128 earnedToDate;
        uint128 userRewardPerTokenPaid;
        uint128 rewards;
    }
    mapping(address => UserRewards) public userRewards;
    
    event RewardAdded(uint256 reward);
    event RewardPaid(address indexed user, uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event ExitStaked(address indexed user);
    event EnterStaked(address indexed user);

    constructor(IERC20 _rewardToken, IERC20 _stakedToken, IWhitelist _whitelistAddress, address _treasuryAddress) {
        require(address(_rewardToken) != address(0) && address(_stakedToken) != address(0) && address(_whitelistAddress) != address(0) && _treasuryAddress != address(0), "PHTK Staking: Cannot addresses to zero address");
        rewardToken = _rewardToken;
        stakedToken = _stakedToken;
        whitelistContract = _whitelistAddress;
        treasury = _treasuryAddress;
    }
    
    modifier onlyWhitelist(address account) {
        require(isWhitelisted(account), "PHTK Staking: User is not whitelisted.");
        _;
    }

    /// @notice Update the rewards amount of the account
    /// @dev This modifier will be executed before each time user stake/withdraw/claimReward
    /// @param account The address of the user
    modifier updateReward(address account) {
        uint128 _rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        rewardPerTokenStored = _rewardPerTokenStored;
        userRewards[account].rewards = earned(account);
        userRewards[account].userRewardPerTokenPaid = _rewardPerTokenStored;
        _;
    }

    /**
     * @dev Returns the amount of stakedToken staked by `account`.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    /**
     * @dev Returns the amount of stakedToken staked by `account`.
     */
    function lastTimeRewardApplicable() public view returns (uint64) {
        uint64 blockTimestamp = uint64(block.timestamp);
        return blockTimestamp < periodFinish ? blockTimestamp : periodFinish;
    }
    /**
     * @dev Returns the amount of stakedToken staked by `account`.
     */
    function rewardPerToken() public view returns (uint128) {
        uint256 totalStakedSupply = totalSupply;
        if (totalStakedSupply == 0)
            return rewardPerTokenStored;
        uint256 rewardDuration = lastTimeRewardApplicable() - lastUpdateTime;
        return uint128(rewardPerTokenStored + rewardDuration * rewardRate * 1e18 / totalStakedSupply);
    }
    /**
    * @notice Returns the amount of earned rewardToken by `account` can be claimed.
    * @param account The address of the user
    * @return amount of rewardToken in wei
    */
    function earned(address account) public view returns (uint128) {
        return uint128(balanceOf(account) * (rewardPerToken() - userRewards[account].userRewardPerTokenPaid) /1e18 + userRewards[account].rewards);
    }
    /**
    * @notice Stake an amount of stakedToken
    * @dev Only whitelist addresses can stake
    * @param amount The parameter is the amount of LP tokens you want to stake (decimals included) 
    * Emit ExitStaked and Staked event
    */
    function stake(uint128 amount) external onlyWhitelist(msg.sender) updateReward(msg.sender) {
        require(amount > 0, "PHTK Staking: Cannot stake 0 Tokens");
        if (_balances[msg.sender] == 0)
            emit EnterStaked(msg.sender);
        stakedToken.safeTransferFrom(msg.sender, address(this), amount);
        totalSupply += amount;
        _balances[msg.sender] += amount;
        emit Staked(msg.sender, amount);
    }
    
    /**
    * @notice Withdraw an amount of stakedToken
    * @dev Only staked addresses can withdraw
    * @param amount The amount of stakedToken user wants to withdraw
    * Emit ExitStaked and Withdrawn event
    */
    function withdraw(uint128 amount) public updateReward(msg.sender) {
        require(amount > 0, "PHTK Staking: Cannot withdraw 0 LP Tokens");
        require(amount <= _balances[msg.sender], "PHTK Staking: Cannot withdraw more LP Tokens than user staking balance");
        if(amount == _balances[msg.sender])
            emit ExitStaked(msg.sender);
        _balances[msg.sender] -= amount;
        totalSupply -= amount;
        stakedToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    
    /**
    * @notice Executing this function claims the earned reward tokens for the user AND 
    claims their LP that is staked in the contract.
    * @dev Cannot claim rewards if rewards have been withdrawn by owner.
    * Emit ExitStaked event
     */
    function exit() external {
        if (!rewardsWithdrawn)
            claimReward();
        withdraw(uint128(balanceOf(msg.sender)));
        emit ExitStaked(msg.sender);
    }
    /**
     * @notice Executing this function claims the earned reward tokens for the user who is staking.
     * @dev If tax is currently greater than 0, then the earned rewards
   tokens sent to the user on a claim will have the tax taken out.
     * Emit RewardPaid event
     */
    function claimReward() public updateReward(msg.sender) {
        require(!rewardsWithdrawn, "PHTK Staking: Cannot claim rewards if rewards have been withdrawn by owner.");
        uint256 reward = userRewards[msg.sender].rewards;
        uint256 tax = 0;
        if(rewardToken.balanceOf(address(this)) <= reward)
            reward = 0;
        if (reward > 0) {
            userRewards[msg.sender].rewards = 0;
            if(currentExitPercent() != 0 && reward != 0){
                tax = reward * currentExitPercent() / 100;
                rewardToken.safeTransfer(treasury, tax);
                emit RewardPaid(treasury, tax);
            }
            rewardToken.safeTransfer(msg.sender, reward - tax);
            userRewards[msg.sender].earnedToDate += uint128(reward - tax);
            emit RewardPaid(msg.sender, reward - tax);
        }
    }

    /**
    * @notice Set rewards amount and staking duration
    * @dev The contract has to have greater or equal @param reward of rewardToken
    * @param reward The amount of rewardToken owner wants to reward staking users
    * @param duration Duration of this staking period in seconds
     */
    function setRewardParams(uint128 reward, uint64 duration) external onlyOwner {
        require(reward > 0);
        rewardPerTokenStored = rewardPerToken();
        uint64 blockTimestamp = uint64(block.timestamp);
        uint256 maxRewardSupply = rewardToken.balanceOf(address(this));
        if(rewardToken == stakedToken)
            maxRewardSupply -= totalSupply;
        uint256 leftover = 0;
        if (blockTimestamp >= periodFinish) {
            rewardRate = reward/duration;
        } else {
            uint256 remaining = periodFinish-blockTimestamp;
            leftover = remaining*rewardRate;
            rewardRate = (reward+leftover)/duration;
        }
        require(reward+leftover <= maxRewardSupply, "PHTK Staking: Not enough tokens to supply Reward Pool");
        lastUpdateTime = blockTimestamp;
        periodFinish = blockTimestamp+duration;
        rewardsWithdrawn = false;
        emit RewardAdded(reward);
    }

    /**
    * @notice Only the Owner can withdraw the remaining Reward Tokens in the Rewards Staking Pool. 
    * @dev Withdrawing these tokens makes APY go to 0 and will result in the staking pool user only being able to withdraw their LP and will receive 0 Reward Tokens (even if the UI says they have earned Reward Tokens)
    */
    function withdrawReward() external onlyOwner {
        uint256 rewardSupply = rewardToken.balanceOf(address(this));
        //ensure funds staked by users can't be transferred out - this only transfers reward token back to contract owner
        if(rewardToken == stakedToken){
            rewardSupply -= totalSupply;
        }
        rewardToken.safeTransfer(msg.sender, rewardSupply);
        rewardRate = 0;
        periodFinish = uint64(block.timestamp);
        rewardsWithdrawn = true;
    }
    
    /**
    * @dev Check if an address is whitelisted
    */
    function isWhitelisted(address account) public view returns (bool) {
       return whitelistContract.isWhitelisted(account);
    }

    /**
    * @notice Allows the Owner  to write the current tax rate. 
    * @dev Tax cannot be greater than 20%
    */
    function updateExitStake(uint8 _exitPercent) external onlyOwner() {
        require(_exitPercent <= 30, "PHTK Staking: Exit percent cannot be greater than 30%");
        exitPercentSet = block.timestamp;
        exitPercent = _exitPercent;
    }

    /**
    * @notice Allows the Owner / Deployer to change the treasury address that receives the tax (if tax is enabled)
    * @dev Treasury address cannot be zero address
    */
    function updateTreasury(address account) external onlyOwner() {
        require(account != address(0), "PHTK Staking: Cannot set treasury as zero address");
        treasury = account;
    }

    /**
    * @notice Number that returns the current exit percent for withdrawing reward tokens. 1% is reduced every day.
    * @dev If daysSincePercentSet is greater than or equal to exitPercent then the currentExitPercent will always return 0;
    */
    function currentExitPercent() public view returns (uint256) {
        uint256 daysSincePercentSet = (block.timestamp - exitPercentSet) / 1 days;
        return daysSincePercentSet <= exitPercent ? exitPercent - daysSincePercentSet : 0;
    }
}