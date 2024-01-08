// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol"; 
import "./ReentrancyGuard.sol";
import "./Context.sol";

contract StakingTokenWrapper is ReentrancyGuard { using SafeERC20 for IERC20; using SafeMath for uint256;
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
        _totalSupply = _totalSupply + _amount;
        _balances[_beneficiary] = _balances[_beneficiary] + _amount;
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Transfer(address(0), _beneficiary, _amount);
    }

    function _withdraw(uint256 _amount) internal nonReentrant {
        require(_balances[msg.sender] >= _amount, "Not enough user rewards");
        _totalSupply = _totalSupply - _amount;
        _balances[msg.sender] = _balances[msg.sender] - _amount;
        stakingToken.safeTransfer(msg.sender, _amount);
        emit Transfer(msg.sender, address(0), _amount);
    }
}

contract StakingRewards is StakingTokenWrapper, Ownable { using SafeERC20 for IERC20; using SafeMath for uint256;
    IERC20 public immutable rewardToken; /// @notice token the rewards are distributed in. eg MTA
    uint256 public immutable DURATION = 30 * 24 * 60 * 60; /// @notice length of each staking period in seconds. 7 days = 604,800; 3 months = 7,862,400

    uint256 public periodFinish = 0; /// @notice Timestamp for current period finish
    uint256 public rewardRate = 0; /// @notice RewardRate for the rest of the period
    uint256 public lastUpdateTime = 0; /// @notice Last time any user took action
    uint256 public rewardPerTokenStored = 0; /// @notice Ever increasing rewardPerToken rate, based on % of total supply

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardChanged(int256 reward); 
    event Staked(address indexed user, uint256 amount, address payer);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    constructor(string memory _name, string memory _symbol, address _stakingToken, address _rewardToken) StakingTokenWrapper(_stakingToken, _name, _symbol) { rewardToken = IERC20(_rewardToken); }
    
    function stake(uint256 _amount) external { _stake(msg.sender, _amount); }
    function stake(address _beneficiary, uint256 _amount) external { _stake(_beneficiary, _amount); }
    function _stake(address _beneficiary, uint256 _amount) internal override updateReward(_beneficiary) {
        super._stake(_beneficiary, _amount);
        emit Staked(_beneficiary, _amount, msg.sender);
    }

    function exit() external { withdraw(balanceOf(msg.sender)); claimReward(); }

    function withdraw(uint256 _amount) public updateReward(msg.sender) { /** @dev Withdraws given stake amount from the pool @param _amount Units of the staked token to withdraw */
        require(_amount > 0, "Cannot withdraw 0");
        _withdraw(_amount);
        emit Withdrawn(msg.sender, _amount);
    }
    
    function claimReward() public updateReward(msg.sender) { /** @dev Claims outstanding rewards for the sender. First updates outstanding reward allocation and then transfers. */
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function lastTimeRewardApplicable() public view returns (uint256) { return block.timestamp < periodFinish ? block.timestamp : periodFinish; } /** @dev Gets the last applicable timestamp for this reward period  */
    function rewardPerToken() public view returns (uint256) { (uint256 rewardPerToken_, ) = _rewardPerToken(); return rewardPerToken_; } /** @dev Calculates the amount of unclaimed rewards per token since last update, and sums with stored to give the new cumulative reward per token */
    function _rewardPerToken() internal view returns (uint256 rewardPerToken_, uint256 lastTimeRewardApplicable_) {
        uint256 lastApplicableTime = lastTimeRewardApplicable(); // + 1 SLOAD
        uint256 timeDelta = lastApplicableTime - lastUpdateTime; // + 1 SLOAD
        if (timeDelta == 0) { return (rewardPerTokenStored, lastApplicableTime); } // If this has been called twice in the same block, shortcircuit to reduce gas
        uint256 rewardUnitsToDistribute = rewardRate * timeDelta; // + 1 SLOAD // new reward units to distribute = rewardRate * timeSinceLastUpdate
        uint256 supply = totalSupply(); // + 1 SLOAD
        if (supply == 0 || rewardUnitsToDistribute == 0) { return (rewardPerTokenStored, lastApplicableTime); } // If there is no StakingToken liquidity, avoid div(0) // If there is nothing to distribute, short circuit
        return (rewardPerTokenStored + (rewardUnitsToDistribute / supply), lastApplicableTime); // + 1 SLOAD // return summed rate
    }

    function earned(address _account) public view returns (uint256) { return _earned(_account, rewardPerToken()); } /** @dev Calculates the amount of unclaimed rewards a user has earned @param _account User address @return Total reward amount earned */
    function _earned(address _account, uint256 _currentRewardPerToken) internal view returns (uint256) {
        uint256 userRewardDelta = _currentRewardPerToken - userRewardPerTokenPaid[_account]; // + 1 SLOAD // current rate per token - rate user previously received
        if (userRewardDelta == 0) { return rewards[_account]; } // Short circuit if there is nothing new to distribute
        uint256 userNewReward = balanceOf(_account) * userRewardDelta; // + 1 SLOAD // new reward = staked tokens * difference in rate
        return rewards[_account] + userNewReward; // add to previous rewards
    }

    modifier updateReward(address _account) { /** @dev Updates the reward for a given address, before executing function */
        (uint256 newRewardPerToken, uint256 lastApplicableTime) = _rewardPerToken(); // Setting of global vars
        if (newRewardPerToken > 0) { // If statement protects against loss in initialisation case
            rewardPerTokenStored = newRewardPerToken;
            lastUpdateTime = lastApplicableTime;
            if (_account != address(0)) { // Setting of personal vars based on new globals
                rewards[_account] = _earned(_account, newRewardPerToken);
                userRewardPerTokenPaid[_account] = newRewardPerToken;
            }
        }
        _;
    }

    function notifyRewardAmount(int256 _rewardDelta) internal onlyOwner updateReward(address(0)) { /** @dev Notifies the contract that new rewards have been added. Calculates an updated rewardRate based on the rewards in period. @param _reward Units of RewardToken that have been added to the pool */
        require((_rewardDelta < 1e24) && (_rewardDelta > -1e24), "Cannot notify with more than 1e24 units");

        uint256 currentTime = block.timestamp;
        int256 newRewardRate;
        if (currentTime >= periodFinish) { newRewardRate = _rewardDelta / int256(DURATION); } // If previous period over, reset rewardRate
        else { // If additional reward to existing period, calc sum
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
}
