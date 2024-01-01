/**
* @author NiceArti (https://github.com/NiceArti) 
* To maintain developer you can also donate to this address - 0xDc3d3fA1aEbd13fF247E5F5D84A08A495b3215FB
* @title The interface for implementing the CryptoFlatsNft smart contract 
* with a full description of each function and their implementation 
* is presented to your attention.
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./IStakingNFT.sol";

enum CflatsRarity { Standart, Silver, Gold, Diamond }

interface ICflatsNftRarity 
{
    function getNFTType(uint256 tokenId) external view returns (CflatsRarity);
}

interface ICflatsNftGenSelector
{
    /**
    * @notice current genesis of Cryptoflats NFT
    * @return uint256
    */ 
    function gen()
        external
        view
        returns(uint256);
}


interface ICflatsStaking is IStakingNFT
{
    event RarityChanged(address indexed stakeToken, uint256 tokenId);


    // Infor for gen1 - gen5
    struct CflatsNftInfo 
    {
        uint256 _profitIncome;
        CflatsRarity _rarity;
    }


    function getUpperStakedRarityOf(
        address staker,
        address stakeToken
    ) external view returns (CflatsRarity);

    function getRewardsForStakeToken(
        address stakeToken,
        uint256 tokenId
    ) external view returns(uint256);

    
    function hasNftPass(address staker) external view returns (bool);
    function hasNftPassStaked(address staker) external view returns (bool);

    

    function addStakeToken(address newStakeToken) 
        external
        returns (bool);

    function removeStakeToken(address newStakeToken) 
        external
        returns (bool);

    function transferRewards(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}