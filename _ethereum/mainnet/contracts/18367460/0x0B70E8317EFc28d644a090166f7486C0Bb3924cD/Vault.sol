// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol"; 
import "./OwnableUpgradeable.sol"; 
import "./Initializable.sol";

interface IStaking {
    function stake(IERC20 pool, uint256 _amount) external;
    function unstake(IERC20 pool, uint256 _amount) external;
}

contract Vault is Initializable, OwnableUpgradeable {
    
    struct Meta {
        uint32 lockDate;        // datetime (epoch time) from which token is locked
        uint64 vettingTime;     // duration of vetting period (in seconds)
        IStaking stakePool; 
    }

    Meta public INFO;
    
    mapping(IERC20 => uint) stakeAmounts;   // stake amount per token
    mapping(IERC20 => uint) withdrawals;    // withdrawn amount per token
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(uint32 lockDate, uint64 time, IStaking stakePool) initializer public {
        __Ownable_init();
        // if (lockDate == 0) lockDate = uint32(block.timestamp);
        if (time == 0) time = uint64(5 * 365 days);

        INFO = Meta(lockDate, time, stakePool);
    }

    function available(IERC20 token) public view returns(uint result) {
        uint elapsed = block.timestamp - INFO.lockDate;
        result = elapsed * stakeAmounts[token] / INFO.vettingTime;
        if (result > stakeAmounts[token]) result = stakeAmounts[token];
        return result - withdrawals[token];
    }

    function lockAndStake(IERC20 token) external {
        if (INFO.lockDate == 0)
            INFO.lockDate = uint32(block.timestamp);
        uint availBalance = token.balanceOf(address(this));
        INFO.stakePool.stake(token, availBalance);
        stakeAmounts[token] += availBalance;
    }

    function withdraw(IERC20 token, uint amount) external onlyOwner {
        if (amount == 0 && token.balanceOf(address(this)) > 0)
            token.transfer(owner(), token.balanceOf(address(this)));
        else {
            uint avail = available(token);
            if (amount == 0) amount = avail;
            require(amount <= avail, 'Insufficient fund');

            withdrawals[token] += amount;

            INFO.stakePool.unstake(token, amount);
            
            token.transfer(owner(), amount);
        }
    }
}