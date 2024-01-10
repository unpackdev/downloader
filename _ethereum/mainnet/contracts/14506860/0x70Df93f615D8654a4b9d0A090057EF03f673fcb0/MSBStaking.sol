//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

abstract contract MSB is ERC721A, Ownable {}

contract StakeMSB is Ownable{
    using SafeMath for uint256;
    MSB public msb;
    mapping(uint256 => uint256) public stakingTimestamp;
    mapping(uint256 => address) stakingAddress;
    mapping(uint256 => bool) isStaked;

    uint256 stakingThresholdTime1;
    uint256 stakingThresholdTime2;
    uint256 private dailyRewards = 10;
    uint256 private maxNormalRewards = 300;
    uint256 private timeBlock = 3600*24;

    uint256 private bonusPercentage1 = 200;
    uint256 private bonusPercentage2 = 50;
    uint256 private bonusPercentage3 = 10;

    bool public claimIsActive;
    mapping(uint256 => uint256) public claimAmount;
    mapping(uint256 => bool) public claimed;
    mapping(uint256 => uint256) public claimedTier;

    struct rewards {
        uint256 baseReward;
        uint256 rewardTier;
        uint256 bonusPercentage;
    }

    constructor() {}

    function setMSBcontract(address contractAddress) external onlyOwner {
        msb = MSB(contractAddress);
    }

    function setThresholds(uint256 timestamp1, uint256 timestamp2) external onlyOwner {
        stakingThresholdTime1 = timestamp1;
        stakingThresholdTime2 = timestamp2;
    }

    function setDailyRewards(uint256 _dailyRewards) external onlyOwner {
        dailyRewards = _dailyRewards;
    }

    function setMaxNormalRewards(uint256 _maxNormalRewards) external onlyOwner {
        maxNormalRewards = _maxNormalRewards;
    }

    function setRewardMultiplier(uint256 _bonusPercentage1, uint256 _bonusPercentage2, uint256 _bonusPercentage3) external onlyOwner {
        bonusPercentage1 = _bonusPercentage1;
        bonusPercentage2 = _bonusPercentage2;
        bonusPercentage3 = _bonusPercentage3;
    }

    function setTimeBlock(uint256 _timeBlock) external onlyOwner {
        timeBlock = _timeBlock;
    }

    function flipClaimState() external onlyOwner {
        claimIsActive = !claimIsActive;
    }

    function stakeMSB(uint256 tokenId) external {
        require(msg.sender == msb.ownerOf(tokenId),"Caller is not the Owner of given NFT");
        require(!claimIsActive,"Staking window has closed");
        stakingAddress[tokenId] = msg.sender;
        stakingTimestamp[tokenId] = block.timestamp;
        isStaked[tokenId] = true;
    }

    function unStakeMSB(uint256 tokenId) external {
        require(msg.sender == msb.ownerOf(tokenId),"Caller is not the Owner of given NFT");
        require(msg.sender == stakingAddress[tokenId],"The NFT was not staked by this address");
        isStaked[tokenId] = false;
    }

    function getStakingStatus(uint256 tokenId) external view returns(bool) {
        bool status = ((isStaked[tokenId]) && msb.ownerOf(tokenId) == stakingAddress[tokenId]);
        return status;
    }

    function calculateRewards(uint256 tokenId) private view returns(rewards memory) {
        rewards memory _rewards;
        _rewards.baseReward = (block.timestamp - stakingTimestamp[tokenId]).div(timeBlock).mul(dailyRewards);

        if (_rewards.baseReward > maxNormalRewards) _rewards.baseReward = maxNormalRewards;

        if(stakingTimestamp[tokenId] <= stakingThresholdTime1) {
            _rewards.rewardTier = 1;
            _rewards.bonusPercentage = bonusPercentage1;
        }
        else if(stakingTimestamp[tokenId] > stakingThresholdTime1 && stakingTimestamp[tokenId] <= stakingThresholdTime2) {
            _rewards.rewardTier = 2;
            _rewards.bonusPercentage = bonusPercentage2;
        }
        else {
            _rewards.rewardTier = 3;
            _rewards.bonusPercentage = bonusPercentage3;
        }

        return _rewards;
    }

    function getCurrentrewards(uint256  tokenId) external view returns(uint256 baseReward, uint256 rewardTier, uint256 bonusPercentage) {
        rewards memory currentRewards;
        bool status = ((isStaked[tokenId]) && msb.ownerOf(tokenId) == stakingAddress[tokenId]);
        if(status) {
            currentRewards = calculateRewards(tokenId);          
        }

        return (currentRewards.baseReward, currentRewards.rewardTier, currentRewards.bonusPercentage);
    }

    function claimTokenRewards(uint256 tokenId) external {
        require(claimIsActive,"Claims are not active");
        require(msg.sender == msb.ownerOf(tokenId),"Caller not owner of NFT");
        require(isStaked[tokenId] && msb.ownerOf(tokenId) == stakingAddress[tokenId],"NFT not staked or not eligible for rewards");
        rewards memory currentRewards;
        currentRewards = calculateRewards(tokenId);
        claimAmount[tokenId] = (currentRewards.baseReward).add((currentRewards.baseReward).mul(currentRewards.bonusPercentage).div(100));
        claimedTier[tokenId] = currentRewards.rewardTier;
        isStaked[tokenId] = false;
        claimed[tokenId] = true;
    }

}