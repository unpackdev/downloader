// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./ICongruentNFT.sol";
import "./IAuctionHouse.sol";

contract AuctionHouseStorage {
    // The ERC721 token contract
    ICongruentNFT public nft;

    // The address of the WETH contract
    address public weth;

    // The amount of NFTs
    uint256 public amount;

    // The minimum price accepted in an auction
    uint256 public reservePrice;

    // The minimum percentage difference between the last bid amount and the current bid
    uint8 public minBidIncrementPercentage;

    // The duration of a single auction
    uint256 public duration;

    // The active auction
    IAuctionHouse.Auction public auction;
}
