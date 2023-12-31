/**
@title LINGO Token
@author Lingo Labs
@dev Staking Contract for Lingo token

Lingo Labs spearheads the transformation of multilingual content creation, 
utilizing cutting-edge AI to eliminate language barriers and encourage global connectivity. 
The $LINGO token operates as the central nerve of this ecosystem, enabling transactions, 
incentivizing community participation, and granting users a stake in the developmental trajectory of the platform. 
Join us in forging a universe where language evolves from a barrier to a conduit uniting content creators and audiences across the globe.

Website: https://lingolabs.xyz
Telegram: https://t.me/LingoLabsAI
X(Twitter): https://twitter.com/LingoLabsAI
Documentation: https://lingo-ai-crafted-multilingual-au.gitbook.io/
Snapshot Voting: https://snapshot.org/#/lingolabs.eth
Mirror: https://mirror.xyz/lingolabs.eth/urgEql--dvWC2URmu28JObuaY3ll0VZo3j3gV_rpkvg
*/
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

    mapping(address => Stake[]) private staked;
    uint256 public totalTokenStaked;
    uint256 public totalRewardsDistributed;
    uint256 public totalRewardPending;
    IERC20 private tokenContract;

    constructor() {
        tokenContract = IERC20(0x1fEDEDf92447F2766b0806aF6e3317a0F7117149);
    }

    function stake(uint256 _amount, uint256 _duration) public {
        uint256 _rewardAmount;
        if(_duration == 3) {
            _rewardAmount = _amount * 101 / 100;
        } else if(_duration == 15) {
            _rewardAmount = _amount * 104 / 100;
        } else if(_duration == 30) {
            _rewardAmount = _amount * 110 / 100;
        } else if(_duration == 90) {
            _rewardAmount = _amount * 140 / 100;
        } else {
            revert("Stake: UNSUPPORTED DURATION.");
        }
        require(tokenContract.allowance(msg.sender, address(this)) >= _amount, "Stake: APPROVE BEFORE STAKE");
        require(tokenContract.balanceOf(msg.sender) >= _amount, "Stake: INSUFFICIENT AMOUNT");

        totalTokenStaked += _amount;
        totalRewardPending += _rewardAmount;
        
        tokenContract.transferFrom(msg.sender, address(this), _amount);

        uint256 _unlockAt = block.timestamp + (_duration * 24 * 60 * 60);

        staked[msg.sender].push(Stake(_amount, _rewardAmount, _unlockAt, _duration, false));
    }

    function unstake(uint256 _stakedPosition) public {
        Stake memory position =  staked[msg.sender][_stakedPosition];
        require(position.rewarded == false, "Stake: ALREADY REWARDED");
        require(position.unlockAt < block.timestamp, "Stake: TOO EARLY FOR UNSTAKE");
        position.rewarded = true;

        tokenContract.transfer(msg.sender, position.rewardAmount);

        totalRewardPending -= position.rewardAmount;
        totalTokenStaked -= position.amount;
        staked[msg.sender][_stakedPosition] = position;
    }

    
    function stakedPosition(address _address, uint256 _stakedPosition) public view returns (Stake memory) {
        return staked[_address][_stakedPosition];
    }    

    function stakedPositions(address _address) public view returns (Stake[] memory) {
        return staked[_address];
    }

    function withdrawStuckTokens(uint256 _amount) external onlyOwner {
        tokenContract.transfer(msg.sender, _amount);
    }
}