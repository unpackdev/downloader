// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
/**
 *Submitted for verification at Etherscan.io on 2020-07-17
 */

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/
* Synthetix: BaseRewardPool.sol
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

import "./Interfaces.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./Math.sol";
import "./Address.sol";
import "./SafeERC20.sol";


contract TokenWrapper is ERC20 {
    using SafeERC20 for IERC20;

    IERC20 public immutable stakingToken;

    constructor(address _stakingToken) ERC20 ("Staked uveCRV", "suveCRV") {
        stakingToken = IERC20(_stakingToken);
    }

    function _stakeFor(address to, uint amount) internal {
        _mint(to, amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    function _withdraw(uint amount) internal {
        _burn(msg.sender, amount);
        stakingToken.safeTransfer(msg.sender, amount);
    }
}


contract FeePool is TokenWrapper {
    using SafeERC20 for IERC20;

    IERC20 public immutable rewardToken;
    uint256 public constant duration = 7 days;

    address public immutable operator;

    address public constant unitVault = address(0xb1cFF81b9305166ff1EFc49A129ad2AfCd7BCf19);

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public queuedRewards = 0;
    uint256 public currentRewards = 0;
    uint256 public historicalRewards = 0;
    uint256 public constant newRewardRatio = 830;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint) public vaultDeposit;

    event RewardAdded(uint256 reward);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    constructor(
        address stakingToken_,
        address rewardToken_,
        address operator_
    ) TokenWrapper(stakingToken_) {
        rewardToken = IERC20(rewardToken_);
        operator = operator_;
    }

    modifier updateReward(address account) {
        _updateReward(account);
        _;
    }

    modifier updateRewardOnTransfer(address from, address to) {
        _updateReward(from);
        _updateReward(to);
        if (to == unitVault) {
            vaultDeposit[from] = IVault(unitVault).collaterals(address(this), from);
        } else if (from == unitVault) {
            vaultDeposit[to] = IVault(unitVault).collaterals(address(this), to);
        }
        _;
    }

    function _updateReward(address account) internal {
        if (account != unitVault) {
            rewardPerTokenStored = rewardPerToken();
            lastUpdateTime = lastTimeRewardApplicable();
            if (account != address(0)) {
                rewards[account] = earned(account);
                userRewardPerTokenPaid[account] = rewardPerTokenStored;
            }
        }
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
        rewardPerTokenStored + (
            (lastTimeRewardApplicable() - lastUpdateTime)
            * rewardRate
            * 1e18
            / totalSupply()
        );
    }

    function earned(address account) public view returns (uint256) {
        return
        (balanceOf(account) + vaultDeposit[account])
        * (rewardPerToken() - userRewardPerTokenPaid[account])
        / 1e18
        + rewards[account];
    }

    function stake(uint256 _amount)
    public
    updateReward(msg.sender)
    returns(bool)
    {
        require(_amount > 0, 'RewardPool : Cannot stake 0');

        super._stakeFor(msg.sender, _amount);

        return true;
    }

    function stakeAll() external returns(bool) {
        uint256 balance = stakingToken.balanceOf(msg.sender);
        stake(balance);
        return true;
    }

    function stakeFor(address _for, uint256 _amount)
    public
    updateReward(_for)
    returns(bool)
    {
        require(_amount > 0, 'RewardPool : Cannot stake 0');

        super._stakeFor(_for, _amount);

        return true;
    }


    function withdraw(uint256 amount, bool claim)
    public
    updateReward(msg.sender)
    returns(bool)
    {
        require(amount > 0, 'RewardPool : Cannot withdraw 0');

        super._withdraw(amount);

        if (claim) {
            getReward(msg.sender);
        }

        return true;
    }

    function withdrawAll(bool claim) external {
        withdraw(balanceOf(msg.sender), claim);
    }

    function getReward(address _account) public updateReward(_account) returns(bool) {
        uint256 reward = rewards[_account];
        if (reward > 0) {
            rewards[_account] = 0;
            rewardToken.safeTransfer(_account, reward);
            emit RewardPaid(_account, reward);
        }
        return true;
    }

    function getReward() external returns(bool) {
        getReward(msg.sender);
        return true;
    }

    function donate(uint256 _amount) external {
        IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), _amount);
        queuedRewards = queuedRewards + _amount;
    }

    function queueNewRewards(uint256 _rewards) external returns(bool) {
        require(msg.sender == operator, "!authorized");

        _rewards = _rewards + queuedRewards;

        if (block.timestamp >= periodFinish) {
            notifyRewardAmount(_rewards);
            queuedRewards = 0;
            return true;
        }

        //et = now - (finish-duration)
        uint256 elapsedTime = block.timestamp - (periodFinish - duration);
        //current at now: rewardRate * elapsedTime
        uint256 currentAtNow = rewardRate * elapsedTime;
        uint256 queuedRatio = currentAtNow * 1000 / _rewards;

        if (queuedRatio < newRewardRatio) {
            notifyRewardAmount(_rewards);
            queuedRewards = 0;
        } else {
            queuedRewards = _rewards;
        }
        return true;
    }

    function notifyRewardAmount(uint256 reward)
    internal
    updateReward(address(0))
    {
        historicalRewards = historicalRewards + reward;
        if (block.timestamp >= periodFinish) {
            rewardRate = reward / duration;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            reward = reward + leftover;
            rewardRate = reward / duration;
        }
        currentRewards = reward;
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + duration;
        emit RewardAdded(reward);
    }

    function transfer(address to, uint amount)
    public
    override
    updateRewardOnTransfer(msg.sender, to)
    returns (bool)
    {
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint amount)
    public
    override
    updateRewardOnTransfer(from, to)
    returns (bool)
    {
        return super.transferFrom(from, to, amount);
    }
}