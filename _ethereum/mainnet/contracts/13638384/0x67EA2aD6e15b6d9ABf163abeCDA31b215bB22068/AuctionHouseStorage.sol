// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ISnoopDAONFT.sol";
import "./IAuctionHouse.sol";

contract AuctionHouseStorage {
    // The ERC721 token contract
    ISnoopDAONFT public snoopDAONFT;

    // The address of the DOG contract
    address public dog;

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
