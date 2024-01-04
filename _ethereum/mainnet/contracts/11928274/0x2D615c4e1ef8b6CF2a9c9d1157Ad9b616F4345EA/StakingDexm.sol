// SPDX-License-Identifier: MIT
/**
 *  DexMex Staking Pool
 * 

           ,-.
       ,--' ~.).
     ,'         `.
    ; (((__   __)))
    ;  ( (#) ( (#)
    |   \_/___\_/|
   ,"  ,-'    `__".
  (   ( ._   ____`.)--._        _
   `._ `-.`-' \(`-'  _  `-. _,-' `-/`.
    ,')   `.`._))  ,' `.   `.  ,','  ;
  .'  .     `--'  /     ).   `.      ;
 ;     `-  1ucky /     '  )         ;
 \                       ')       ,'
  \                     ,'       ;
   \               `~~~'       ,'
    `.                      _,'
      `.                ,--'
        `-._________,--'
  *
*/


pragma solidity ^0.7.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IDexm.sol";

contract StakingDexm is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    
    address public DEXM;
    mapping(address => UserInfo) public userInfo;
    uint256 accETHPerShare;
    uint256 public totalRewards;

    constructor(address dexmex) {
        DEXM = dexmex;
    }

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    receive() external payable {
        totalRewards = totalRewards.add(msg.value);
        _updatePool(msg.value);
    }

    function deposit(uint256 amount) public nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(accETHPerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                safeETHTransfer(msg.sender, pending);
            }
        }
        IDexm(DEXM).transferFrom(address(msg.sender), address(this), amount);
        user.amount = user.amount.add(amount);
        user.rewardDebt = user.amount.mul(accETHPerShare).div(1e12);
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) public nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= amount, "withdraw too much");
        uint256 pending = user.amount.mul(accETHPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            safeETHTransfer(msg.sender, pending);
        }
        if (amount > 0) {
            user.amount = user.amount.sub(amount);
            IDexm(DEXM).transfer(msg.sender, amount);
        }
        user.rewardDebt = user.amount.mul(accETHPerShare).div(1e12);
        emit Withdraw(msg.sender, amount);
    }

    function claim() public nonReentrant {
        if (userInfo[msg.sender].amount == 0) {
            return;
        }
        UserInfo storage user = userInfo[msg.sender];
        uint256 pending = user.amount.mul(accETHPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            safeETHTransfer(msg.sender, pending);
        }
        user.rewardDebt = user.amount.mul(accETHPerShare).div(1e12);
    }

    function emergencyWithdraw() public {
        UserInfo storage user = userInfo[msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        IDexm(DEXM).transfer(msg.sender, amount);
        emit EmergencyWithdraw(msg.sender, amount);
    }

    function _updatePool(uint256 reward) internal {
        uint256 totalDeposits = IDexm(DEXM).balanceOf(address(this));
        if (totalDeposits == 0) {
            return;
        }
        accETHPerShare = accETHPerShare.add(reward.mul(1e12).div(totalDeposits));
    }

    function safeETHTransfer(address to, uint256 amount) internal {
        uint256 remain = address(this).balance;
        if (remain < amount) {
            amount = remain;
        }
        payable(to).transfer(amount);
    }

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
}