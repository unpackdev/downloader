//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.12;

interface IPartyBid {

    // total ETH deposited by all contributors
    function totalContributedToParty() external view returns (uint256);
    // the highest bid submitted by PartyBid
    function highestBid() external view returns (uint256);
    //market wrapper contract exposing interface for market auctioning the NFT
    function marketWrapper() external view returns (address);
    // ID of auction within market contract
    function auctionId() external view returns (uint256);
    
    // contribute to partybid
    function contribute() external payable;
    // trigger party to bid on auction
    function bid() external;
}