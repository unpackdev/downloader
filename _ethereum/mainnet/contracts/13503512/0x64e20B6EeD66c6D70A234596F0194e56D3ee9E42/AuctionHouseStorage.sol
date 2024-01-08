// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ISquidDAONFT.sol";
import "./IAuctionHouse.sol";

contract AuctionHouseStorage {
    // The ERC721 token contract
    ISquidDAONFT public squidDAONFT;

    // The address of the WETH contract
    address public weth;

    // The minimum amount of time left in an auction after a new bid is created
    uint256 public timeBuffer;

    // The minimum price accepted in an auction
    uint256 public reservePrice;

    // The minimum percentage difference between the last bid amount and the current bid
    uint8 public minBidIncrementPercentage;

    // The duration of a single auction
    uint256 public duration;

    // The active auction
    IAuctionHouse.Auction public auction;
}
