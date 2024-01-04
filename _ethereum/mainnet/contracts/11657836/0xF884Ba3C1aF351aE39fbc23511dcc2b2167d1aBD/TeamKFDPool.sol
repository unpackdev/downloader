pragma solidity ^0.6.0;
/**
 *Submitted for verification at Etherscan.io on 2020-07-17
 */

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

* Synthetix: BASISCASHRewards.sol
*
* Docs: https://docs.synthetix.io/
*
*
* MIT License
* ===========
*
* Copyright (c) 2020 Synthetix
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

// File: @openzeppelin/contracts/math/Math.sol

import "./Math.sol";

// File: @openzeppelin/contracts/math/SafeMath.sol

import "./SafeMath.sol";

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

import "./IERC20.sol";

// File: @openzeppelin/contracts/utils/Address.sol

import "./Address.sol";

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

import "./SafeERC20.sol";

contract TeamKFDPool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public cash;
    uint256 public DURATION = 5 days;
    
    address public owner;

    uint256 public starttime;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public totalReward = 10000*(1e18);
    uint256 public totalTeam = 3;
    uint256 public teamNum = 0;

    mapping (address => bool) public team;
    mapping (address => uint256) public lastRewardTimes;
    
    event RewardPaid(address indexed user, uint256 amount);

    constructor(
        address cash_,
        uint256 starttime_
    ) public {
        owner = msg.sender;
        cash = IERC20(cash_);
        starttime = starttime_;
        periodFinish = starttime.add(DURATION);

    }

    modifier onlyOwner {
        require(msg.sender == owner, "not owner");
        _;
    }

    modifier checkStart() {
        require(block.timestamp >= starttime, 'KFDBACPool: not start');
        _;
    }

    function setTeam(address account,  bool tag)
        external
        onlyOwner
    {
        if (tag) {
            require(teamNum < totalTeam, "Team > 3");
            team[account] = tag;
            teamNum++;
        } else {
            team[account] = tag;
            teamNum--;
        }
    }
    
    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    /**
    * @dev get reward
    */
   function getReward() public
   {
        uint256 reward = earned(msg.sender);
        require(reward > 0, "must > 0");
        cash.safeTransfer(msg.sender, reward);
        lastRewardTimes[msg.sender] = lastTimeRewardApplicable();
        emit RewardPaid(msg.sender, reward);
    }

    /**
    * @dev  Calculate and reuturn Unclaimed rewards 
    */
    function earned(address account) public view checkStart returns (uint256)  {
        require(team[account], "must is team account");
        uint256 reward = 0;
        uint256 rewardPerTime = totalReward.div(teamNum).div(DURATION);
        uint256 lastRewardTime = lastRewardTimes[account];

        // fist time get 20%
        uint256 durationTime = 0;
        if( lastRewardTime == 0 ){
            durationTime = lastTimeRewardApplicable().sub(starttime);
        }else{
            durationTime = lastTimeRewardApplicable().sub(lastRewardTime);
        }
        reward = durationTime.mul(rewardPerTime);
        if (reward > cash.balanceOf(address(this))) {
            reward = cash.balanceOf(address(this));
        }
        return reward;
   }
}
