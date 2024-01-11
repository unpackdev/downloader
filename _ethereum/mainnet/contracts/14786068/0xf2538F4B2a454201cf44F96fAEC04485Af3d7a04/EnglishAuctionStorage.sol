// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IAccessManager.sol";

abstract contract EnglishAuctionStorage {
    uint32 lastAuctionId;
    address payable public withdrawalAddress;
    IAccessManager accessManager;

    struct AuctionStruct {
        uint32 tokenId;
        uint32 timeStart;
        uint32 timeEnd;
        uint8 minBidPercentage;
        uint256 initialPrice;
        uint256 minBidValue;
        uint256 auctionBalance;
        address nftContractAddress;
        address finalizeAuctionControllerAddress;
        address payable bidder;
        bytes additionalDataForFinalizeAuction;
    }

    mapping(uint32 => AuctionStruct) auctionIdToAuction;
}
