// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import {Ownable} from "Ownable.sol";

import {Timestamp, blockTimestamp, zeroTimestamp} from "IBaseTypes.sol";
import {UFixed, UFixedType} from "UFixedMath.sol";
import {NftId} from "IChainNft.sol";


contract RewardHelper is
    Ownable,
    UFixedType
{
    uint256 public constant MAX_REWARD_RATE_VALUE = 333;
    int8 public constant MAX_REWARD_RATE_EXP = -3;
    uint256 public constant YEAR_DURATION = 365 days;

    struct RewardInfo {
        UFixed rewardRate;
        Timestamp createdAt;
        Timestamp updatedAt;
    }

    event LogTargetRewardRateSet(
        address user,
        NftId target,
        UFixed oldRewardRate,
        UFixed newRewardRate
    );

    event LogDefaultRewardRateSet(
        address user,
        UFixed oldRewardRate,
        UFixed newRewardRate
    );

    // target specific reward rate (apr)
    mapping(NftId target => RewardInfo rewardRate) internal _targetRewardRate;

    // default reward rate (apr)
    UFixed internal _rewardRate;
    UFixed internal _rewardRateMax; // max apr for staking rewards


    constructor() Ownable() {
        _rewardRateMax = itof(MAX_REWARD_RATE_VALUE, MAX_REWARD_RATE_EXP);
    }


    function setRewardRate(UFixed newRewardRate)
        external
        onlyOwner
    {
        require(newRewardRate <= _rewardRateMax,"ERROR:RRH-010:REWARD_EXCEEDS_MAX_VALUE");

        UFixed oldRewardRate = _rewardRate;
        _rewardRate = newRewardRate;

        emit LogDefaultRewardRateSet(owner(), oldRewardRate, _rewardRate);
    }


    function setTargetRewardRate(NftId target, UFixed newRewardRate)
        external
        onlyOwner
    {
        require(newRewardRate <= _rewardRateMax,"ERROR:RRH-020:REWARD_EXCEEDS_MAX_VALUE");

        RewardInfo storage info = _targetRewardRate[target];
        UFixed oldRewardRate = info.rewardRate;

        info.rewardRate = newRewardRate;
        info.updatedAt = blockTimestamp();

        if (info.createdAt == zeroTimestamp()) {
            info.createdAt = blockTimestamp();
            oldRewardRate = _rewardRate;
        }

        emit LogTargetRewardRateSet(
            owner(),
            target,
            oldRewardRate,
            newRewardRate
        );
    }


    function maxRewardRate() external view returns (UFixed) {
        return _rewardRateMax;
    }


    function rewardRate() external view returns (UFixed) {
        return _rewardRate;
    }


    function getTargetRewardRate(NftId target)
        public 
        view 
        returns(UFixed)
    {
        RewardInfo memory info = _targetRewardRate[target];

        if (info.createdAt > zeroTimestamp()) {
            return info.rewardRate;
        }

        // fallback if no target specific rate is defined
        return _rewardRate;
    }


    function calculateRewards(uint256 amount, uint256 duration, UFixed rate)
        public 
        pure 
        returns(uint256 rewardAmount)
    {
        UFixed yearFraction = itof(duration) / itof(YEAR_DURATION);
        UFixed rewardDuration = rate * yearFraction;
        rewardAmount = ftoi(itof(amount) * rewardDuration);
    }
}
