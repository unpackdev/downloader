// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./PausableUpgradeable.sol";
import "./IERC721.sol";
import "./ReentrancyGuardUpgradeable.sol";


import "./IAuctionMarketPlace.sol";
import "./NFTation.sol";
import "./AuctionMarketPlaceStorage.sol";

contract AuctionMarketPlace is IAuctionMarketPlace, Initializable,UUPSUpgradeable, OwnableUpgradeable, PausableUpgradeable,
                               ReentrancyGuardUpgradeable,AuctionMarketPlaceStorage {

    constructor() {}

    function initialize() initializer public {
        __UUPSUpgradeable_init();
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();


        auctionDuration  = 1 days;
        auctionExtendDuration = 15 minutes;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    function initToken(address _NFTationContract,uint8 marketPlaceSharePercentage) public onlyOwner {
        NFTationContract = NFTation(_NFTationContract);
        marketPlaceShare = marketPlaceSharePercentage;
    }

    function changeMarketPlaceShare(uint8 _marketPlaceShare) external onlyOwner {
        marketPlaceShare = _marketPlaceShare;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setAuctionTiming(uint256 _auctionDuration,uint256 _auctionExtendDuration) external onlyOwner {
        require (_auctionDuration >= _auctionExtendDuration,"AuctionMarkerPlace: Auction Extend Duration must be less than Auction Duration");
        auctionDuration = _auctionDuration;
        auctionExtendDuration = _auctionExtendDuration;
    }

    function createAuction(uint256 _tokenId,  uint256 _minBidPrice) external nonReentrant whenNotPaused {
        Auction storage auction = auctionMapping[_tokenId];
        auction.minBidPrice = _minBidPrice;
        auction.seller = msg.sender;
        auction.initiated = true;
        //external call
        NFTationContract.transferFrom(msg.sender, address(this), _tokenId);

        emit AuctionCreated(_tokenId, _minBidPrice);
    }

    function placeBid(uint256 _tokenId) payable external nonReentrant whenNotPaused {
        Auction storage auction = auctionMapping[_tokenId];
        require(auction.initiated, "AuctionMarkerPlace: Auction not initiated.");
        require(auction.startedAt == 0 || block.timestamp <= auction.startedAt + auctionDuration || block.timestamp < auction.lastBidAt + auctionExtendDuration, "AuctionMarketPlace: Auction times up.");
        require(msg.value >= auction.minBidPrice, "AuctionMarketPlace: Bid Should be more than minimum bid price.");
        require(msg.value >= auction.lastBidAmount * 11 / 10, "AuctionMarketPlace: Bid should be 10% more than last bid.");
        require(msg.sender != auction.seller, "AuctionMarketPlace: Seller can not bid on its owned auction.");
        bool isFirstBid = false;
        address lastBidBidder = auction.lastBidBidder;
        uint256 lastBidAmount = auction.lastBidAmount;
        auction.lastBidAmount = msg.value;
        auction.lastBidBidder = msg.sender;
        auction.lastBidAt = block.timestamp;
        if (!auction.hasBid) {
            auction.startedAt = block.timestamp;
            auction.hasBid = true;
            isFirstBid = true;
        } else {
            //external call
            (bool sent, ) = payable(lastBidBidder).call{value: lastBidAmount}("") ;
            if(!sent){
                pendingWidthrawMapping[_tokenId][lastBidBidder] =lastBidAmount;
            }
        }
        uint256 endAt = (auction.startedAt + auctionDuration) > (auction.lastBidAt + auctionExtendDuration) ? auction.startedAt + auctionDuration : auction.lastBidAt + auctionExtendDuration;
        emit AuctionBidSubmitted(_tokenId, msg.value, msg.sender, isFirstBid, endAt);
    }

    function settle(uint256 _tokenId) external whenNotPaused nonReentrant { 

        Auction memory auction = auctionMapping[_tokenId];
        require(auction.initiated, "AuctionMarkerPlace: Auction not initiated.");
        require(auction.hasBid, "AuctionMarkerPlace: Auction not started yet.");
        require(block.timestamp > auction.startedAt + auctionDuration && block.timestamp > auction.lastBidAt + auctionExtendDuration, "AuctionMarketPlace: auction not finished yet.");
        (uint256 marketPlaceShareAmount, uint256 royaltyAmount, address tokenCreator) = getMarketShareAndRoyalty(_tokenId, auction.lastBidAmount);
        uint256 remaining = auction.lastBidAmount - (marketPlaceShareAmount + royaltyAmount);
        delete auctionMapping[_tokenId];

        //External call / transfer ether
        bool sent;
        (sent, ) = payable(owner()).call{value: marketPlaceShareAmount}("") ;
        require(sent);
        if(royaltyAmount > 0){
            (sent, ) = payable(tokenCreator).call{value: royaltyAmount}("") ;
            require(sent);
        }
        if(NFTationContract.checkFirstSale(_tokenId))
            NFTationContract.disableFirstSale(_tokenId);

        NFTationContract.transferFrom(address(this) ,auction.lastBidBidder, _tokenId);
        (sent, ) = payable(auction.seller).call{value: remaining}("") ;
        require(sent);
        emit AuctionFinished(_tokenId, auction.lastBidBidder, auction.lastBidAmount ,msg.sender);
    }

    function cancelAuction(uint256 _tokenId) external whenNotPaused nonReentrant {
        Auction memory auction = auctionMapping[_tokenId];
        require(auction.initiated, "AuctionMarkerPlace: Auction not initiated.");
        require(!auction.hasBid, "AuctionMarkerPlace: Auction started.");
        require(auction.seller == msg.sender, "AuctionMarkerPlace: Only seller can cancel auction.");
        delete auctionMapping[_tokenId];

        //externall call
        NFTationContract.transferFrom(address(this) ,msg.sender,  _tokenId);
        emit AuctionCanceled(_tokenId);
    }

    function changeMinBidPrice(uint256 _tokenId, uint256 _newMinBidPrice) external whenNotPaused {
        Auction storage auction = auctionMapping[_tokenId];

        require(auction.initiated, "AuctionMarkerPlace: Auction not initiated.");
        require(!auction.hasBid, "AuctionMarkerPlace: Auction started.");
        require(auction.seller == msg.sender, "AuctionMarkerPlace: Only seller can change minimum bid price of auction.");
        auction.minBidPrice = _newMinBidPrice;
        emit AuctionMinBidPriceChanged(_tokenId, _newMinBidPrice);
    }

    function getMarketShareAndRoyalty(uint256 tokenId, uint256 price) private view returns(uint256 marketShareAmount, uint256 royaltyAmount, address creator) {
        bool isFirstSale = NFTationContract.checkFirstSale(tokenId);
        if(isFirstSale) {
            marketShareAmount = price * (marketPlaceShare + NFTationContract.getRoyaltyPercentage(tokenId)) / 100;
            return(marketShareAmount, 0, address(0));
        } else {
             marketShareAmount = ((marketPlaceShare *price) /100);
            (creator, royaltyAmount) = NFTationContract.royaltyInfo(tokenId , (price));
            return(marketShareAmount, royaltyAmount,creator);
        }
    }

    function withdraw(uint256 _tokenId) external nonReentrant  {
        uint balance = pendingWidthrawMapping[_tokenId][msg.sender];
        pendingWidthrawMapping[_tokenId][msg.sender] = 0;
        (bool sent, ) = payable(msg.sender).call{value: balance}("") ;
        require(sent);
    }

    function getAuctionMapping (uint256 _tokenId) view external returns(Auction memory ){
        return auctionMapping[_tokenId];
    }

    function getPendingWidthrawMapping (uint256 _tokenId,address _address) view external returns(uint256 ){
        return pendingWidthrawMapping[_tokenId][_address];
    }
}