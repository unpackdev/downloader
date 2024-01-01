/**
* @author NiceArti (https://github.com/NiceArti) 
* To maintain developer you can also donate to this address - 0xDc3d3fA1aEbd13fF247E5F5D84A08A495b3215FB
* @title The interface for implementing the CryptoFlatsNft smart contract 
* with a full description of each function and their implementation 
* is presented to your attention.
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IStakingNFT
{
    event ReceivedNFT(address indexed operator, address indexed owner, uint256 indexed tokenId, bytes data);
    event StakedNFT(address indexed owner, address indexed stakeToken, uint256 id);
    event UnstakedNFT(address indexed owner, address indexed stakeToken, uint256 id);
    event RewardsClaimed(address indexed owner, uint256 rewards);
    event RewardsTransferred(address indexed from, address indexed to, uint256 amount);


    struct StakedInfoNFT
    {
        // time when current nft was staked
        uint256 timestamp;

        // NFT ids of user
        uint256[] ids;

        // save id positions for gas saving
        mapping(uint256 => uint256) idPos;
    }


    function isStakerOf(
        address staker,
        address stakeToken,
        uint256 tokenId
    ) 
        external
        view 
        returns (bool);

    function isStakeToken(address stakeToken) 
        external
        view
        returns (bool);

    function getRewardToken() external view returns (address);
    function getUpdatePeriod() external pure returns (uint256);

    function stakedBalanceOf(
        address staker,
        address stakeToken
    ) external view returns (uint256);

    function stakedTimestampOf(
        address staker,
        address stakeToken
    ) external view returns (uint256);

    function rewardsOf(address staker)
        external
        view
        returns (uint256);

    function stakedTokensOf(
        address staker,
        address stakeToken
    ) 
        external 
        view 
        returns (uint256[] memory);

    function claimRewards(
        address stakeToken,
        uint256 amount
    ) external returns (bool);

    
    function stake(
        address stakeToken,
        uint256 tokenId
    ) external returns (bool);


    function unstake(
        address stakeToken,
        uint256 tokenId
    ) external returns (bool);

    function updateRewards(
        address staker,
        address stakeToken
    ) external;

    function batchUpdateRewards(
        address staker,
        address[] memory stakeTokens
    ) external;

    
    function batchStake(
        address[] memory stakeTokens,
        uint256[] memory tokenIds,
        uint256[] memory tokenIdsLength
    ) external returns (bool);


    function batchUnstake(
        address[] memory stakeTokens,
        uint256[] memory tokenIds,
        uint256[] memory tokenIdsLength
    ) external returns (bool);
}