//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract SimpleAuctionsEth is Ownable{

    mapping(address => mapping(uint256 => Auction)) public auctions; // map token address and token id to auction
    mapping(address => bool) public sellers; // Only authorized sellers can make auctions

    //Each Auction is unique to each NFT (contract + id pairing).
    struct Auction {
        uint256 auctionEnd;
        uint128 minPrice;
        uint128 nftHighestBid;
        address nftHighestBidder;
        address nftSeller;
        address erc20Token;
    }

    uint32 public bidIncreasePercentage; // 100 == 1% -> every bid must be higher than the previous
    uint64 public auctionBidPeriod; // in seconds. The lenght of time between last bid and auction end. Auction duration increases if new bid is made in this period before auction end.
    uint64 public minAuctionDuration; // in seconds 86400 = 1 day
    uint64 public maxAuctionDuration; // in seconds 2678400 = 1 month

    /* ========== EVENTS ========== */
    
    event AuctionCreated(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        address erc20Token,
        uint128 minPrice,
        uint256 auctionEnd
    );

    event BidMade(
        address nftContractAddress,
        uint256 tokenId,
        address bidder,
        address erc20Token,
        uint256 tokenAmount
    );

    event AuctionCompleted(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        uint128 nftHighestBid,
        address nftHighestBidder,
        address erc20Token
    );

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _seller,
        uint32 _bidIncreasePercentage,
        uint64 _auctionBidPeriod,
        uint64 _minAuctionDuration, 
        uint64 _maxAuctionDuration 
        ) {
        sellers[_seller] = true;
        bidIncreasePercentage = _bidIncreasePercentage;
        auctionBidPeriod = _auctionBidPeriod;
        minAuctionDuration = _minAuctionDuration;
        maxAuctionDuration = _maxAuctionDuration; 
    }

    /* ========== CREATE AUCTION ========== */

    function createAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _minPrice,
        uint256 _auctionEnd
    )
        external
    {
        require(sellers[msg.sender], "Unauthorized");
        require(_minPrice > 0, "Price cannot be 0");
        require(block.timestamp + minAuctionDuration <= _auctionEnd && block.timestamp + maxAuctionDuration >= _auctionEnd, "Invalid auctionEnd");
        require(_erc20Token != address(0), "ERC20 invalid");

        auctions[_nftContractAddress][_tokenId].minPrice = _minPrice;
        auctions[_nftContractAddress][_tokenId].nftSeller = msg.sender;
        auctions[_nftContractAddress][_tokenId].erc20Token = _erc20Token;
        auctions[_nftContractAddress][_tokenId].auctionEnd = _auctionEnd;
        
        emit AuctionCreated(
            _nftContractAddress,
            _tokenId,
            msg.sender,
            _erc20Token,
            _minPrice,
            _auctionEnd
        );
    }

    /* ========== MAKE BID ========== */

    function makeBid(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _tokenAmount
    )
        external
        payable
    {
        require(block.timestamp < auctions[_nftContractAddress][_tokenId].auctionEnd, "Auction has ended");
        require(msg.sender != auctions[_nftContractAddress][_tokenId].nftSeller, "Owner cannot bid on own NFT");
        require(_erc20Token == auctions[_nftContractAddress][_tokenId].erc20Token, "Wrong ERC20");
        require(_tokenAmount >= auctions[_nftContractAddress][_tokenId].minPrice && 
            _tokenAmount * 10000 >= (auctions[_nftContractAddress][_tokenId].nftHighestBid *
                (10000 + bidIncreasePercentage)),
            "Bid too low");

        if(auctions[_nftContractAddress][_tokenId].nftHighestBid != 0) {
            IERC20(_erc20Token).transfer(
                auctions[_nftContractAddress][_tokenId].nftHighestBidder,
                auctions[_nftContractAddress][_tokenId].nftHighestBid
            );
        }

        IERC20(_erc20Token).transferFrom(
            msg.sender,
            address(this),
            _tokenAmount
        );

        auctions[_nftContractAddress][_tokenId].nftHighestBid = _tokenAmount;
        auctions[_nftContractAddress][_tokenId].nftHighestBidder = msg.sender;

        if(block.timestamp + auctionBidPeriod > auctions[_nftContractAddress][_tokenId].auctionEnd){
            auctions[_nftContractAddress][_tokenId].auctionEnd = block.timestamp + auctionBidPeriod;
        }

        emit BidMade(
            _nftContractAddress,
            _tokenId,
            msg.sender,
            _erc20Token,
            _tokenAmount
        );
    }

    /* ========== SETTLE AUCTION ========== */

    function settleAuction(address _nftContractAddress, uint256 _tokenId)
        external
    {
        require(block.timestamp >= auctions[_nftContractAddress][_tokenId].auctionEnd, "Auction ongoing");
        
        address _nftSeller = auctions[_nftContractAddress][_tokenId].nftSeller;
            
        address _nftHighestBidder = auctions[_nftContractAddress][_tokenId].nftHighestBidder;
        
        uint128 _nftHighestBid = auctions[_nftContractAddress][_tokenId].nftHighestBid;

        address _erc20Token = auctions[_nftContractAddress][_tokenId].erc20Token;

        if(_nftHighestBid != 0) {
            IERC20(_erc20Token).transfer(_nftSeller, _nftHighestBid);  
        }

        auctions[_nftContractAddress][_tokenId].nftHighestBidder = address(0);
        auctions[_nftContractAddress][_tokenId].nftHighestBid = 0;
        auctions[_nftContractAddress][_tokenId].minPrice = 0;
        auctions[_nftContractAddress][_tokenId].auctionEnd = 0;
        auctions[_nftContractAddress][_tokenId].nftSeller = address(0);
        auctions[_nftContractAddress][_tokenId].erc20Token = address(0);

        emit AuctionCompleted(
            _nftContractAddress,
            _tokenId,
            _nftSeller,
            _nftHighestBid,
            _nftHighestBidder,
            _erc20Token
        );
    }
    
    /* ========== SETTINGS ========== */

    function setAuctionBidPeriod(uint32 _auctionBidPeriod) external onlyOwner {
        auctionBidPeriod = _auctionBidPeriod;
    }

    function setBidIncreasePercentage(uint32 _bidIncreasePercentage) external onlyOwner {
        bidIncreasePercentage = _bidIncreasePercentage;
    }

    function setAuctionDuration(uint64 _minAuctionDuration, uint64 _maxAuctionDuration) external onlyOwner {
        minAuctionDuration = _minAuctionDuration;
        maxAuctionDuration = _maxAuctionDuration;
    }

    function addSeller(address _seller) external onlyOwner {
        sellers[_seller] = true;
    }

    function removeSeller(address _seller) external onlyOwner {
        sellers[_seller] = false;
    }
}