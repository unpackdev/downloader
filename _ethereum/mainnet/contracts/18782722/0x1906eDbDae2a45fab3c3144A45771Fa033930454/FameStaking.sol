// SPDX-License-Identifier: MIT

pragma solidity =0.8.22;

import "./IERC20.sol";
import "./SafeERC20.sol";

import "./Ownable.sol";
import "./Unchecked.sol";


/**
 * Stake and lock FAME and EARN FAME
 */
contract FameStaking is Ownable {

    using SafeERC20 for IERC20;
    
    // EVENTS
    event Withdraw(address indexed user, uint256 amount);
    event Deposit(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    
   
    // ERROR
    error SetupError();
    error NotYet();
    error NoShares();
    error Locked();
    error InvalidAmount();
    error NotEnoughTokens();
    error NotEnoughReward();

    address public token;
    uint public lastUpdateTime;
    uint public totalAmount;
    uint public tokenPerSec;
    uint public accTokenPerShare;
    uint constant public ACC_PRECISION = 1e18;
    uint constant public LOCK_PERIOD = 7 days;

    mapping(address => UserInfo) public userInfos;

    struct UserInfo {
        uint amount;
        uint lockTimeStamp;
        uint pendingReward;
        uint rewardDebt;
    }
    
    constructor(
        address _token, 
        uint _startTime, 
        uint _tokenPerSec
    )
        Ownable(msg.sender)
    {
        if(_startTime < block.timestamp) revert SetupError();

        lastUpdateTime = _startTime;
        token = _token;
        tokenPerSec = _tokenPerSec;
    }

    /*
     * @notice set token per sec, onlyOwner. will update pool before execution.
     */
    function setTokenPerSec(uint _tokenPerSec) external onlyOwner {
        update();
        tokenPerSec = _tokenPerSec;
    }
    
    /*
     * @notice update pool status: accTokenPerShare & lastUpdateTime
     */
    function update() public  {
        if(lastUpdateTime >= block.timestamp) return;
        if(totalAmount == 0) {
            lastUpdateTime = block.timestamp;
            return;
        }

        uint256 multiplier = _getMultiplier(lastUpdateTime, block.timestamp);
        
        uint256 pending = multiplier * tokenPerSec;
        if(pending > 0) {
            accTokenPerShare = accTokenPerShare + (pending * ACC_PRECISION) / totalAmount;
            
            lastUpdateTime = block.timestamp;
        }
    }


    function _getMultiplier(uint _lastUpdateTime, uint _now) internal pure returns (uint) {
        if(_lastUpdateTime >= _now) return 0;
        return _now - _lastUpdateTime;
    }


    /*
     * @notice Deposit staked tokens
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function deposit(uint256 _amount) external {
        UserInfo storage user = userInfos[msg.sender];
        
        update();
        
        if (user.amount > 0) {
            uint256 pending = user.amount * accTokenPerShare / ACC_PRECISION - user.rewardDebt;
            if (pending > 0) {
                user.pendingReward = user.pendingReward + pending;
            }
        }

        if (_amount > 0) {
            user.amount = user.amount + _amount;
            totalAmount = totalAmount + _amount;
            IERC20(token).safeTransferFrom(address(msg.sender), address(this), _amount);
        }
        user.rewardDebt = user.amount * accTokenPerShare / ACC_PRECISION;
        user.lockTimeStamp = block.timestamp;
        
        emit Deposit(msg.sender, _amount);
    }

    
    /*
     * @notice internal function to withdraw staked tokens and collect reward tokens
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function withdraw(uint256 _amount) internal {
        if(userInfos[msg.sender].amount == 0) revert NoShares();

        UserInfo storage user = userInfos[msg.sender];
        if(user.lockTimeStamp + LOCK_PERIOD > block.timestamp) revert Locked();
        if(user.amount < _amount) revert InvalidAmount();

        update();

        if (_amount > 0) {
            if(totalAmount < _amount) 
                revert InvalidAmount();
            uint256 pending = user.amount * accTokenPerShare / ACC_PRECISION - user.rewardDebt + user.pendingReward;
            // if not enough to distribute reward
            if(pending > _getRewardTokenBalance()) 
                revert NotEnoughReward();
            
            totalAmount = totalAmount - _amount;
            user.amount = user.amount - _amount;
            user.pendingReward = 0;
            if(user.amount == 0) user.lockTimeStamp = 0;

            IERC20(token).safeTransfer(address(msg.sender), _amount + pending);
        }

        user.rewardDebt = user.amount * accTokenPerShare / ACC_PRECISION;

        emit Withdraw(msg.sender, _amount);
    }

    /*
     * @notice Withdraw and collect reward. Always withdraw all staked amount.
     */
    function withdrawAll() external {
        UserInfo memory user = userInfos[msg.sender];
        withdraw(user.amount);
    }

    
    /*
     * @notice View function to check pending reward
     * @param _user: user address
     * @return Pending reward for a given user
     */
    function getPendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfos[_user];
        // uint256 stakedTokenSupply = stakedToken.balanceOf(address(this));
        if (block.timestamp > lastUpdateTime && totalAmount != 0) {
            uint256 multiplier = _getMultiplier(lastUpdateTime, block.timestamp);
            uint256 reward = multiplier * tokenPerSec;
            uint256 adjustedTokenPerShare =
                accTokenPerShare + reward * ACC_PRECISION / totalAmount;
            return user.pendingReward + user.amount * adjustedTokenPerShare / ACC_PRECISION - user.rewardDebt;
        } else {
            return user.pendingReward + user.amount * accTokenPerShare / ACC_PRECISION - user.rewardDebt;
        }
    }
    
    
    function _getRewardTokenBalance() internal view returns (uint256 rewardBalance) {
        rewardBalance = IERC20(token).balanceOf(address(this));
        if(rewardBalance >= totalAmount) {
            rewardBalance = rewardBalance - totalAmount;
        }else {
            rewardBalance = 0;
        }
        
    }

    /*
     * @notice Withdraw staked tokens without caring about rewards rewards
     * @dev Needs to be for emergency.
     */
    function emergencyWithdraw() external {
        if(lastUpdateTime > block.timestamp) revert NotYet();
        if(userInfos[msg.sender].amount == 0) revert NoShares();

        UserInfo storage user = userInfos[msg.sender];
        if(user.lockTimeStamp + LOCK_PERIOD > block.timestamp) revert Locked();        

        uint256 amountToTransfer = user.amount;
        if(totalAmount < amountToTransfer) revert NotEnoughTokens();

        totalAmount = totalAmount - amountToTransfer;
        user.amount = 0;
        user.pendingReward = 0;
        user.rewardDebt = 0;
        user.lockTimeStamp = 0;

        if (amountToTransfer > 0) {
            IERC20(token).safeTransfer(address(msg.sender), amountToTransfer);
        }

        emit EmergencyWithdraw(msg.sender, user.amount);
    }


    /*
     * @notice Stop rewards
     * @dev Only callable by owner. Needs to be for emergency.
     */
    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        if(_getRewardTokenBalance() < _amount) revert NotEnoughTokens();

        IERC20(token).safeTransfer(msg.sender, _amount);
    }
    
    

    

}