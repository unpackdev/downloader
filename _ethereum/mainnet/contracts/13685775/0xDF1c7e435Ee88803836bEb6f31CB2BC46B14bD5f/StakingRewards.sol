// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

// import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol"; 
import "./ReentrancyGuard.sol";
import "./Context.sol";
import "./StableMath.sol";
import "./console.sol";

contract StakingTokenWrapper is ReentrancyGuard { 
    
    using SafeERC20 for IERC20;
    // using SafeMath for uint256;
    using StableMath for uint256;


    event Transfer(address indexed from, address indexed to, uint256 value);

    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    IERC20 public immutable stakingToken;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    constructor(address _stakingToken, string memory _nameArg, string memory _symbolArg) { 
        stakingToken = IERC20(_stakingToken); 
        name = _nameArg;
        symbol = _symbolArg;
    }

    function totalSupply() public view returns (uint256) { return _totalSupply; }
    function balanceOf(address _account) public view returns (uint256) { return _balances[_account]; }

    function _stake(address _beneficiary, uint256 _amount) internal virtual nonReentrant {
        require(_amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply + _amount;
        _balances[_beneficiary] = _balances[_beneficiary] + _amount;
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Transfer(address(0), _beneficiary, _amount);
    }

    function _withdraw(uint256 _amount) internal nonReentrant {
        require(_amount > 0, "Cannot withdraw 0");
        require(_balances[msg.sender] >= _amount, "Not enough user rewards");
        _totalSupply = _totalSupply - _amount;
        _balances[msg.sender] = _balances[msg.sender] - _amount;
        stakingToken.safeTransfer(msg.sender, _amount);
        emit Transfer(msg.sender, address(0), _amount);
    }
}

contract StakingRewards is StakingTokenWrapper, Ownable { 
    
    // using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using StableMath for uint256;

    uint public lastPauseTime;
    bool public paused;

    /// @notice token the rewards are distributed in. eg MTA
    IERC20 public immutable rewardToken; 

    /// @notice length of each staking period in seconds. 7 days = 604,800; 3 months = 7,862,400
    uint256 public immutable DURATION = 30 days; 

    /// @notice Timestamp for current period finish
    uint256 public periodFinish = 0; 

    /// @notice RewardRate for the rest of the period
    uint256 public rewardRate = 0; 

    /// @notice Last time any user took action
    uint256 public lastUpdateTime = 0; 

    /// @notice Ever increasing rewardPerToken rate, based on % of total supply
    uint256 public rewardPerTokenStored = 0; 

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardChanged(int256 reward); 
    event Staked(address indexed user, uint256 amount, address payer);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event Recovered(address token, uint256 amount);

    constructor(
        string memory _name,
        string memory _symbol,
        address _stakingToken,
        address _rewardToken
    ) StakingTokenWrapper(
        _stakingToken,
        _name,
        _symbol
    ) {
        rewardToken = IERC20(_rewardToken); 
    }
    
    function stake(uint256 _amount) external {
        _stake(msg.sender, _amount);
    }
    
    function stake(address _beneficiary, uint256 _amount) external {
        _stake(_beneficiary, _amount);
    }

    function _stake(address _beneficiary, uint256 _amount) internal override notPaused updateReward(_beneficiary) {
        super._stake(_beneficiary, _amount);
        emit Staked(_beneficiary, _amount, msg.sender);
    }

    function exit() external { withdraw(balanceOf(msg.sender)); claimReward(); }

    /** 
        @dev Withdraws given stake amount from the pool @param _amount Units of the staked token to withdraw 
    */
    function withdraw(uint256 _amount) public updateReward(msg.sender) {
        require(_amount > 0, "Cannot withdraw 0");
        _withdraw(_amount);
        emit Withdrawn(msg.sender, _amount);
    }
    
    /** 
        @dev Claims outstanding rewards for the sender. First updates outstanding reward allocation and then transfers. 
    */
    function claimReward() public updateReward(msg.sender) { 
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    /** @dev Gets the last applicable timestamp for this reward period  */
    function lastTimeRewardApplicable() public view returns (uint256) { 
        return getTimestamp() < periodFinish ? getTimestamp() : periodFinish;
    } 

    /** @dev Calculates the amount of unclaimed rewards per token since last update, and sums with stored to give the new cumulative reward per token */
    function rewardPerToken() public view returns (uint256) {
        (uint256 rewardPerToken_, ) = _rewardPerToken();
        return rewardPerToken_; 
    } 

    function _rewardPerToken() internal view returns (uint256 rewardPerToken_, uint256 lastTimeRewardApplicable_) {
        uint256 lastApplicableTime = lastTimeRewardApplicable(); // + 1 SLOAD
        uint256 timeDelta = lastApplicableTime - lastUpdateTime; // + 1 SLOAD
        if (timeDelta == 0) {
            // If this has been called twice in the same block, shortcircuit to reduce gas
            return (rewardPerTokenStored, lastApplicableTime); 
        } 

        // new reward units to distribute = rewardRate * timeSinceLastUpdate
        uint256 rewardUnitsToDistribute = rewardRate * timeDelta; // + 1 SLOAD 
        uint256 supply = totalSupply(); // + 1 SLOAD

        // If there is no StakingToken liquidity, avoid div(0) 
        // If there is nothing to distribute, short circuit
        if (supply == 0 || rewardUnitsToDistribute == 0) { 
            return (rewardPerTokenStored, lastApplicableTime); 
        } 

        // new reward units per token = (rewardUnitsToDistribute * 1e18) / totalTokens
        uint256 unitsToDistributePerToken = divPrecisely(rewardUnitsToDistribute, supply);

        // return summed rate
        return (rewardPerTokenStored + unitsToDistributePerToken, lastApplicableTime); // + 1 SLOAD 
    }

    uint256 FULL_SCALE = 1e18;

    function divPrecisely(uint256 x, uint256 y) internal view returns (uint256) {
        // e.g. 8e18 * 1e18 = 8e36
        // e.g. 8e36 / 10e18 = 8e17
        return (x * FULL_SCALE) / y;
    }

    /** 
        @dev Calculates the amount of unclaimed rewards a user has earned 
        @param _account User address 
        @return Total reward amount earned 
    */
    function earned(address _account) public view returns (uint256) {
        return _earned(_account, rewardPerToken());
    }

    function _earned(address _account, uint256 _currentRewardPerToken)
        internal
        view
        returns (uint256)
    {
        // current rate per token - rate user previously received
        uint256 userRewardDelta = _currentRewardPerToken - userRewardPerTokenPaid[_account]; // + 1 SLOAD

        // Short circuit if there is nothing new to distribute
        if (userRewardDelta == 0) { 
            return rewards[_account];
        } 

        // new reward = staked tokens * difference in rate
        uint256 userNewReward = balanceOf(_account).mulTruncate(userRewardDelta); // + 1 SLOAD

        // add to previous rewards
        return rewards[_account] + userNewReward; // / FULL_SCALE; 
    }

    /** 
        @dev Updates the reward for a given address, before executing function
    */
    modifier updateReward(address _account) {
        (uint256 newRewardPerToken, uint256 lastApplicableTime) = _rewardPerToken(); // Setting of global vars
        // If statement protects against loss in initialisation case
        if (newRewardPerToken > 0) { 
            rewardPerTokenStored = newRewardPerToken;
            lastUpdateTime = lastApplicableTime;
            
            // Setting of personal vars based on new globals
            if (_account != address(0)) { 
                rewards[_account] = _earned(_account, newRewardPerToken);
                userRewardPerTokenPaid[_account] = newRewardPerToken;
            }
        }
        _;
    }

    /** 
        @dev Notifies the contract that new rewards have been added. Calculates an updated rewardRate based on the rewards in period.
        @param _rewardDelta Units of RewardToken that have been added to the pool 
    */
    function notifyRewardAmount(int256 _rewardDelta) internal onlyOwner updateReward(address(0)) { 
        require((_rewardDelta < 1e24) && (_rewardDelta > -1e24), "Cannot notify with more than a million units");

        uint256 currentTime = getTimestamp();
        int256 newRewardRate;

        // If previous period over, reset rewardRate
        if (currentTime >= periodFinish) { 
            newRewardRate = _rewardDelta / int256(DURATION);
        } 
        else
        { 
            // If additional reward to existing period, calc sum
            uint256 remaining = periodFinish - currentTime;
            uint256 leftover = remaining * rewardRate;
            newRewardRate = (_rewardDelta + int256(leftover)) / int256(DURATION);
        }

        require(newRewardRate >= 0, "newRewardRate must be positive");
        rewardRate = uint256(newRewardRate);
        lastUpdateTime = currentTime;
        periodFinish = currentTime + DURATION;
        emit RewardChanged(_rewardDelta);
    }

    function adjustReward(int256 rewardDelta) external onlyOwner { 
        if (rewardDelta > 0) { rewardToken.transferFrom(this.owner(), address(this), uint256(rewardDelta)); }
        else { rewardToken.transfer(this.owner(), uint256(-rewardDelta)); }
        notifyRewardAmount(rewardDelta);
    }

    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAddress != address(stakingToken), "Cannot withdraw the staking token");
        IERC20(tokenAddress).safeTransfer(this.owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    /**
     * @notice Change the paused state of the contract
     * @dev Only the contract owner may call this.
     */
    function setPaused(bool _paused) external onlyOwner {
        // Ensure we're actually changing the state before we do anything
        if (_paused == paused) {
            return;
        }

        // Set our paused state.
        paused = _paused;

        // If applicable, set the last pause time.
        if (paused) {
            lastPauseTime = getTimestamp();
        }

        // Let everyone know that our pause state has changed.
        emit PauseChanged(paused);
    }

    event PauseChanged(bool isPaused);

    modifier notPaused {
        require(!paused, "This action cannot be performed while the contract is paused");
        _;
    }

    function getTimestamp() public view virtual returns (uint256) {
        return block.timestamp;
    }
}
