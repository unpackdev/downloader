// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
/**
 *Submitted for verification at Etherscan.io on 2020-07-17
 */

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

* Synthetix: ETHlfETHLPTokenSharePool.sol
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

// File: contracts/IRewardDistributionRecipient.sol

import "./IRewardDistributionRecipient.sol";
import "./IBoardroom.sol";
import "./IBasisAsset.sol";
import "./LPTokenWrapper.sol";

import "./Operator.sol";


contract WETHlfETHLPTokenSharePool is
    LPTokenWrapper,
    IRewardDistributionRecipient,
    Operator
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public boardroom;
    address public share; // lift

    uint256 public DURATION = 365 days;

    uint256 public starttime;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lockoutPeriod = 30; // days stuck for that free genesis money
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lockedOutDate;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    constructor(
        address _boardroom,
        address _share,
        address _lptoken,
        uint256 _starttime
    ) {
        boardroom = _boardroom;
        share = _share;
        lpt = _lptoken;
        starttime = _starttime;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function daysRemaining() external view returns (uint256) {
        return ((block.timestamp - lockedOutDate[msg.sender]) / 60 / 60 / 24);
    }


    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 amount)
        public
        updateReward(msg.sender)
    {
        require(amount > 0, 'ETHlfETHLPTokenSharePool: Cannot stake 0');
        super.stake(msg.sender, msg.sender, amount);
        emit Staked(msg.sender, amount);
    }

    function stakeLP(address staker, address from, uint256 amount, bool lockout) external updateReward(staker)
    {
        require(amount > 0, 'ETHlfETHLPTokenSharePool: cannot stake 0');
        
        if(lockout) lockedOutDate[msg.sender] = block.timestamp;
        
        super.stake(staker, from, amount);
        emit Staked(staker, amount);
    }

    function withdraw(uint256 amount)
        public
        override
        updateReward(msg.sender)
    {
        require(amount > 0, 'ETHlfETHLPTokenSharePool: Cannot withdraw 0');
        
        require(((lockedOutDate[msg.sender] - block.timestamp) / 60 / 60 / 24) > lockoutPeriod, 'ETHlfETHLPTokenSharePool: still in lockout period');
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        stakeInBoardroom();
    }

    function stakeInBoardroom() public updateReward(msg.sender) {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;

            IERC20(share).approve(boardroom, reward);
            IBoardroom(boardroom).stakeShareForThirdParty(msg.sender, address(this), reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function notifyRewardAmount(uint256 reward)
        external
        override
        onlyRewardDistribution
        updateReward(address(0))
    {
        if (block.timestamp > starttime) {
            if (block.timestamp >= periodFinish) {
                rewardRate = reward.div(DURATION);
            } else {
                uint256 remaining = periodFinish.sub(block.timestamp);
                uint256 leftover = remaining.mul(rewardRate);
                rewardRate = reward.add(leftover).div(DURATION);
            }
            lastUpdateTime = block.timestamp;
            periodFinish = block.timestamp.add(DURATION);
            emit RewardAdded(reward);
        } else {
            rewardRate = reward.div(DURATION);
            lastUpdateTime = starttime;
            periodFinish = starttime.add(DURATION);
            emit RewardAdded(reward);
        }
    }

    //EVERY PROJECT I HAVE SEEN HAS A NEED TO NUKE THEIR LP AT SOME POINT
    function burnRewards() external onlyOwner
    {
         IBasisAsset(share).burn(IERC20(share).balanceOf(address(this)));
    }

    // supports the evolution of the boardroom without ending staking
    function updateBoardroom(address newBoardroom) external onlyOwner
    {
        boardroom = newBoardroom;
    }
}
