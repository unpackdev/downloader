// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.4;

library FNVvoucher {
    
    struct mintVoucher{
        uint256 tokenId;
        uint256 amount;
        uint96 royaltyFees;
        address royaltyKeeper;
        address nftAddress;
        address nftOwner;
        string tokenUri;
        bytes signature;
    }
    struct priListing{
        uint256 tokenId;
        uint256 unitprice;
        uint256 countervalue;
        uint256 amount;
        address nftOwner;
        bool listed;
        bool isEth;
        bytes signature;
        
    }

    struct marketItem {
        uint256 tokenId;
        uint256 unitPrice;
        uint256 nftBatchAmount;
        uint256 counterValue;
        address nftAddress;
        address owner;
        string tokenURI;
        bool listed;
        bool isEth;
        bytes signature;
        
    }

    struct auctionItemSeller {
        uint96 royaltyFees;
        uint256 tokenId;
        uint256 nftBatchAmount;
        uint256 minimumBid;
        address nftAddress;
        address owner;
        address royaltyKeeper;
        string tokenURI;
        bool isEth;
        bytes signature;
        
    }
    struct secAuctionItemSeller {
        uint256 minimumBid;
        uint256 tokenId;
        uint256 nftBatchAmount;
        address nftAddress;
        address owner;
        string tokenURI;
        bool isEth;
        bytes signature;
        
    }

    struct auctionItemBuyer {
            uint256 tokenId;
            uint256 nftBatchAmount;
            uint256 pricePaid;
            address nftAddress;
            address buyer;
            string tokenURI;
            bytes signature;
    }
}