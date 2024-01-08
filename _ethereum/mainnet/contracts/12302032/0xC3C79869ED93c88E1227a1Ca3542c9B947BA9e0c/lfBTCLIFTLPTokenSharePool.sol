// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

//Contract deployed by LK Tech Club Incubator 2021 dba Lift.Kitchen - 4/24/2021
/**
 *Submitted for verification at Etherscan.io on 2020-07-17
 */

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

* Synthetix: lfBTCLIFTLPTokenSharePool.sol
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
import "./Operator.sol";

import "./LPTokenWrapper.sol";

//import "./console.sol";

contract lfBTCLIFTLPTokenSharePool is
    LPTokenWrapper,
    IRewardDistributionRecipient,
    Operator
{
    using SafeMath for uint256;        
    using SafeERC20 for IERC20;

    address public share; //lift
    address public boardroom;

    uint256 public DURATION = 730 days;

    uint256 public starttime;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    
    uint public TermOne = 30;
    uint public TermTwo = 60;
    uint public TermThree = 90;
    uint public TermFour = 120;

    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lockedOutDate;

    struct StakingSeat {
        //staked tokens * currentMultiplier
        uint256 notmultipliedNumbWBTCTokens;
        uint256 multipliedNumWBTCTokens2x;
        uint256 multipliedNumWBTCTokens3x;
        uint256 multipliedNumWBTCTokens4x;
        uint256 multipliedNumWBTCTokens5x;
        bool isEntity;
    }

    mapping(address => StakingSeat) private stakers;

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

    function daysElapsed() external view returns (uint256) {
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
        require(amount > 0, 'lfBTCLIFTLPTokenSharePool: Cannot stake 0');
        StakingSeat memory seat = stakers[msg.sender];
        seat.notmultipliedNumbWBTCTokens += amount;
        stakers[msg.sender] = seat;  
        super.stake(msg.sender, msg.sender, amount);
        emit Staked(msg.sender, amount);
    }

    function stakeLP(address staker, address from, uint256 amount, uint term) external updateReward(staker)
    {
        require(amount > 0, 'lfBTCLIFTLPTokenSharePool: cannot stake 0');
        require(term >= 1 && term <= 4, 'lfBTCLIFTLPTokenSharePool: invalid term specified');

        StakingSeat memory seat = stakers[staker];

        if(term == 1) {
            seat.multipliedNumWBTCTokens2x += amount;
        } else if (term == 2) {
            seat.multipliedNumWBTCTokens3x += amount;
        } else if (term == 3) {
            seat.multipliedNumWBTCTokens4x += amount;
        } else if (term == 4) {
            seat.multipliedNumWBTCTokens5x += amount;
        }

        stakers[staker] = seat;  
        
        lockedOutDate[staker] = block.timestamp;
        super.stake(staker, from, amount);
        emit Staked(staker, amount);
    }

    //we are ignoring the amount.  
    function withdraw(uint256 amount)
        public
        override
        updateReward(msg.sender)
    {
        StakingSeat memory seat = stakers[msg.sender];
        uint256 tokensAvailable = 0;
        uint256 tokensWithdrawn = 0;

        if (seat.notmultipliedNumbWBTCTokens > 0) {
            tokensAvailable = seat.notmultipliedNumbWBTCTokens;
            seat.notmultipliedNumbWBTCTokens = 0;
            stakers[msg.sender] = seat;  
            tokensWithdrawn = tokensAvailable;
            super.withdraw(tokensAvailable);
            emit Withdrawn(msg.sender, tokensAvailable);
        }

        if ((block.timestamp - lockedOutDate[msg.sender]) / 60 / 60 / 24 >= TermOne) {
            if (seat.multipliedNumWBTCTokens2x > 0) {
                tokensAvailable = seat.multipliedNumWBTCTokens2x;
                seat.multipliedNumWBTCTokens2x = 0;
                stakers[msg.sender] = seat;  
                tokensWithdrawn += tokensAvailable;
                super.withdraw(tokensAvailable);
                emit Withdrawn(msg.sender, tokensAvailable);
            }
        } else {
            return;
        }

        if ((block.timestamp - lockedOutDate[msg.sender]) / 60 / 60 / 24 >= TermTwo) {            
            if (seat.multipliedNumWBTCTokens3x > 0) {
                tokensAvailable = seat.multipliedNumWBTCTokens3x;
                seat.multipliedNumWBTCTokens3x = 0;
                stakers[msg.sender] = seat;  
                tokensWithdrawn += tokensAvailable;
                super.withdraw(tokensAvailable);
                emit Withdrawn(msg.sender, tokensAvailable);
            }
        } else {
            return;
        }

        if ((block.timestamp - lockedOutDate[msg.sender]) / 60 / 60 / 24 >= TermThree) {            
            if (seat.multipliedNumWBTCTokens4x > 0) {
                tokensAvailable = seat.multipliedNumWBTCTokens4x;
                seat.multipliedNumWBTCTokens4x = 0;
                stakers[msg.sender] = seat;  
                tokensWithdrawn += tokensAvailable;
                super.withdraw(tokensAvailable);
                emit Withdrawn(msg.sender, tokensAvailable);
            }
        } else {
            return;
        }

        if ((block.timestamp - lockedOutDate[msg.sender]) / 60 / 60 / 24 >= TermFour) {            
            if (seat.multipliedNumWBTCTokens5x > 0) {
                tokensAvailable = seat.multipliedNumWBTCTokens5x;
                seat.multipliedNumWBTCTokens5x = 0;
                stakers[msg.sender] = seat;  
                tokensWithdrawn += tokensAvailable;
                super.withdraw(tokensAvailable);
                emit Withdrawn(msg.sender, tokensAvailable);
            }
        } else {
            return;
        }

        require(tokensWithdrawn > 0, 'lfBTCLIFTLPTokenSharePool: no tokens eligible for withdrawl due to lockout period');

        emit Withdrawn(msg.sender, tokensWithdrawn);
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

    // If anyone sends tokens directly to the contract we can refund them.
    function cleanUpDust(uint256 amount, address tokenAddress, address sendTo) onlyOperator public  {     
        require(tokenAddress != lpt, 'If you need to withdrawl lpt use the DAO to migrate to a new contract');

        IERC20(tokenAddress).safeTransfer(sendTo, amount);
    }

    function updateStakingToken(address newToken) public onlyOperator {
        lpt = newToken;
    }
 
    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
}
