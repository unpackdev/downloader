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
        address erc20Token; // Auction can be in any ERC20 token or in ETH. If erc20Token is address(0), it means that auction is in ETH
    }

    uint32 public bidIncreasePercentage; // 100 == 1% -> every bid must be higher than the previous
    uint64 public auctionBidPeriod; // in seconds. The lenght of time between last bid and auction end. Auction duration increases if new bid is made in this period before auction end.
    uint64 public minAuctionDuration; // in seconds 86400 = 1 day
    uint64 public maxAuctionDuration; // in seconds 2678400 = 1 month
    mapping(address => uint256) public failedTransferCredits;

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

    /* ========== PRIVATE FUNCTIONS ========== */

    function _isERC20Auction(address _auctionERC20Token)
        internal
        pure
        returns (bool)
    {
        return _auctionERC20Token != address(0);
    }

    function _payout(
        address _erc20Token,
        address _recipient,
        uint256 _amount
    ) internal {
        if (_isERC20Auction(_erc20Token)) {
            IERC20(_erc20Token).transfer(_recipient, _amount);
        } else {
            // attempt to send the funds to the recipient
            (bool success, ) = payable(_recipient).call{
                value: _amount,
                gas: 20000
            }("");
            // if it failed, update their credit balance so they can pull it later
            if (!success) {
                failedTransferCredits[_recipient] =
                    failedTransferCredits[_recipient] +
                    _amount;
            }
        }
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
        require(auctions[_nftContractAddress][_tokenId].nftHighestBid == 0, "Cannot override auction");
        require(_minPrice > 0, "Price cannot be 0");
        require(block.timestamp + minAuctionDuration <= _auctionEnd && block.timestamp + maxAuctionDuration >= _auctionEnd, "Invalid auctionEnd");

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
        Auction memory auction = auctions[_nftContractAddress][_tokenId];

        require(block.timestamp < auction.auctionEnd, "Auction has ended");
        require(msg.sender != auction.nftSeller, "Owner cannot bid on own NFT");
        require(_erc20Token == auction.erc20Token, "Wrong ERC20");

        uint128 bidAmount = _tokenAmount;

        if (_isERC20Auction(_erc20Token)) { // Check if auction is in ERC20 or in native currency

            require(msg.value == 0 &&
                _tokenAmount >= auction.minPrice && 
                _tokenAmount * 10000 >= (auction.nftHighestBid *
                (10000 + bidIncreasePercentage)) , "Payment not accepted");

            IERC20(_erc20Token).transferFrom(
                msg.sender,
                address(this),
                _tokenAmount
            );

        } else {

            require(_tokenAmount == 0 &&
                msg.value >= auction.minPrice && 
                msg.value * 10000 >= (auction.nftHighestBid *
                (10000 + bidIncreasePercentage)) , "Payment not accepted");

            bidAmount = uint128(msg.value);

        }

        auctions[_nftContractAddress][_tokenId].nftHighestBidder = msg.sender;
        auctions[_nftContractAddress][_tokenId].nftHighestBid = bidAmount;

        if(block.timestamp + auctionBidPeriod > auction.auctionEnd){
            auctions[_nftContractAddress][_tokenId].auctionEnd = block.timestamp + auctionBidPeriod;
        }
        
        if(auction.nftHighestBid != 0) {
            _payout(_erc20Token, auction.nftHighestBidder, auction.nftHighestBid);
        }

        emit BidMade(
            _nftContractAddress,
            _tokenId,
            msg.sender,
            _erc20Token,
            bidAmount
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
            _payout(_erc20Token, _nftSeller, _nftHighestBid);
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