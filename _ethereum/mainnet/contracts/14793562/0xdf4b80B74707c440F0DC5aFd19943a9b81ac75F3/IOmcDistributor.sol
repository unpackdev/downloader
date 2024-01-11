//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IOmcDistributor {
    event Compound(
        uint256 _epochNum,
        uint256 _totalRewardAmount,
        uint256 _rewardPerUser,
        uint256 _totalMinerCount
    );
    event RewardWithdrawal(
        uint256 _tokenId,
        uint256 _tokenEpoch,
        uint256 _reward
    );

    function compound(
        uint256 epochNum,
        uint256 totalRewardAmount,
        uint256 totalSupply
    ) external;

    function setOmc(address omc) external;

    function setOmcEpoch(address omcEpoch) external;

    function pendingReward(uint256 tokenId) external view returns (uint256);

    function withdrawReward(uint256 tokenId) external;
}
