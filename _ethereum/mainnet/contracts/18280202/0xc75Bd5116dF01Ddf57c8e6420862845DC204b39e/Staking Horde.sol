// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./IERC20.sol";

contract Staking is Ownable {
    struct Stake {
        uint256 amount;
        uint256 rewardAmount;
        uint256 unlockAt;
        uint256 duration;
        bool rewarded;
    }

    mapping(address => Stake) private staked;
    uint256 public totalTokenStaked;
    uint256 public totalRewardsDistributed;
    uint256 public totalRewardPending;
    uint256 public totalStakers;
    IERC20 private tokenContract;

    constructor() {
        tokenContract = IERC20(0x2Da82DE4b505f2226f5Db319D2c2449495D5E45e);
    }

    function stake(uint256 _amount, uint256 _duration) public {
        Stake memory position =  staked[msg.sender];
        if(position.unlockAt == 0) totalStakers++;
        
        uint256 _rewardAmount;
        if(_duration == 1) {
            _rewardAmount = _amount * 10005 / 10000; // 18.25%
        } else if(_duration == 11) {
            _rewardAmount = _amount * 1007 / 1000; // 21.90%
        } else if(_duration == 21) {
            _rewardAmount = _amount * 1015 / 1000; // 26.07%
        } else if(_duration == 30) {
            _rewardAmount = _amount * 103 / 100; // 35.32%
        } else {
            revert("Stake: UNSUPPORTED DURATION.");
        }
        require(tokenContract.allowance(msg.sender, address(this)) >= _amount, "Stake: APPROVE BEFORE STAKE");
        require(tokenContract.balanceOf(msg.sender) >= _amount, "Stake: INSUFFICIENT AMOUNT");

        totalTokenStaked += _amount;
        totalRewardPending += _rewardAmount;
        
        tokenContract.transferFrom(msg.sender, address(this), _amount);

        uint256 _unlockAt = block.timestamp + (_duration * 24 * 60 * 60);

        staked[msg.sender] = Stake(_amount, _rewardAmount, _unlockAt, _duration, false);
    }

    function unstake() public {
        Stake memory position =  staked[msg.sender];
        require(position.rewarded == false, "Stake: ALREADY REWARDED");
        require(position.unlockAt < block.timestamp, "Stake: TOO EARLY FOR UNSTAKE");
        position.rewarded = true;

        tokenContract.transfer(msg.sender, position.rewardAmount);

        totalRewardsDistributed += position.rewardAmount;
        totalRewardPending -= position.rewardAmount;
        totalTokenStaked -= position.amount;
        staked[msg.sender] = position;
    }
    function stakedPositions(address _address) public view returns (Stake memory) {
        return staked[_address];
    }

    function withdrawStuckTokens(uint256 _amount) external onlyOwner {
        tokenContract.transfer(msg.sender, _amount);
    }
}