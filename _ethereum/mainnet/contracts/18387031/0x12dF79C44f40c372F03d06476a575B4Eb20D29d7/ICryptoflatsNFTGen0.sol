/**
* @author NiceArti (https://github.com/NiceArti) 
* To maintain developer you can also donate to this address - 0xDc3d3fA1aEbd13fF247E5F5D84A08A495b3215FB
* @title The interface for implementing the CryptoFlatsNft smart contract 
* with a full description of each function and their implementation 
* is presented to your attention.
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


enum CryptoflatsValue {Standart, Silver, Gold, Diamond}


interface ICryptoflatsNFTGen0
{
    /**
    * @notice an event that trigers when team wallet is transferred
    * @param from - address of user who called transfer event
    * @param oldTeamWalletAddress - old address of team wallet
    * @param newTeamWalletAddress - new address of team wallet
    */
    event TeamWalletTransferred (
        address indexed from,
        address indexed oldTeamWalletAddress,
        address indexed newTeamWalletAddress
    );

    /**
    * @notice an event that trigers when nft type changed
    * @param id - token id
    * @param newNftType - new nft type setted
    */
    event CryptoflatsNftTypeChanged (
        uint256 id,
        string newNftType
    );



    /**
    * @notice the public address of the team that receives a reward 
    * in the form of 5% from the resale of the NFT. Also, to maintain 
    * the project, you can also donate to this address
    * @return address 
    */
    function teamWallet()
        external
        view
        returns (address payable);




    /**
    * @notice current genesis of Cryptoflats NFT
    * @return uint256
    */ 
    function gen()
        external
        view
        returns(uint256);



    /**
    * @dev accessible only via contract owner
    * @param newTeamWallet - new team wallet address
    * @notice if for some reason there is a need to change the address of the 
    * team's wallet to a new one, then the owner will have the opportunity to
    * do this in order to save the assets received for the contract
    */ 
    function setNewTeamWallet(address payable newTeamWallet) external;



    /**
    * @dev accessible only via contract owner
    * @notice since the funds that users pay for the purchase of NFT go
    * into the contract, it is necessary to allow the owner to collect
    * the funds accumulated in the contract after user purchases
    * @return bool if balance withdraw was success
    */
    function withdrawBalance() external returns(bool);
}