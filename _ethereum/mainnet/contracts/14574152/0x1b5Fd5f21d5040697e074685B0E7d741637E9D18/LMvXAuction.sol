// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";


/**
 * @notice Primary sale auction contract for Living Modules Vx NFTs
 */
contract LMvXAuction is Ownable {
    using SafeMath for uint256;
    using Address for address payable;
    using SafeERC20 for IERC20;


    event AuctionCreated(
        uint256 indexed tokenId,
        uint256 reservePrice,
        uint256 startTimestamp,
        uint256 endTimestamp
    );

    event UpdateAuctionEndTime(
        uint256 indexed tokenId,
        uint256 endTime
    );

    event UpdateAuctionStartTime(
        uint256 indexed tokenId,
        uint256 startTime
    );

    event UpdateAuctionReservePrice(
        uint256 indexed tokenId,
        uint256 reservePrice
    );

    event UpdateMinBidIncrement(
        uint256 minBidIncrement
    );

    event UpdateBidWithdrawalLockTime(
        uint256 bidWithdrawalLockTime
    );

    event BidPlaced(
        uint256 indexed tokenId,
        address indexed bidder,
        uint256 bid
    );

    event BidWithdrawn(
        uint256 indexed tokenId,
        address indexed bidder,
        uint256 bid
    );

    event BidRefunded(
        address indexed bidder,
        uint256 bid
    );

    event AuctionResulted(
        uint256 indexed tokenId,
        address indexed winner,
        uint256 winningBid
    );

    event AuctionCancelled(
        uint256 indexed tokenId
    );

    /// @notice Parameters of an auction
    struct Auction {
        uint256 reservePrice;
        uint256 startTime;
        uint256 endTime;
        bool resulted;
    }

    /// @notice Information about the sender that placed a bid on an auction
    struct HighestBid {
        address payable bidder;
        uint256 bid;
        uint256 lastBidTime;
    }

    /// @notice LMvX Token ID -> Auction Parameters
    mapping(uint256 => Auction) public auctions;

    /// @notice LMvX Token ID -> highest bidder info (if a bid has been received)
    mapping(uint256 => HighestBid) public highestBids;

    /// @notice LMvX NFT - the only NFT that can be auctioned in this contract
    IERC721 public nftToken;

    /// @notice STARL erc20 token
    IERC20 public token;

    /// @notice globally and across all auctions, the amount by which a bid has to increase
    uint256 public minBidIncrement = 50000000 * (10 ** 18);

    /// @notice global bid withdrawal lock time
    uint256 public bidWithdrawalLockTime = 30 minutes;

    /// @notice Fee recipient that represents volunteer devs
    address payable public devFeeRecipient;

    constructor(
        IERC721 _nftToken,
        IERC20 _token,
        address payable _devFeeRecipient
    ) public {
        require(address(_nftToken) != address(0), "Invalid NFT");
        require(address(_token) != address(0), "Invalid Token");
        require(_devFeeRecipient != address(0), "Invalid Dev Fee Recipient");

        nftToken = _nftToken;
        token = _token;
        devFeeRecipient = _devFeeRecipient;
    }

    /**
     @notice Creates a new auction for a given nft
     @dev Only the owner of a nft can create an auction and must have approved the contract
     @dev End time for the auction must be in the future.
     @param _tokenIds List of Token ID of the nft being auctioned
     @param _reservePrice Nft cannot be sold for less than this or minBidIncrement, whichever is higher
     @param _startTimestamp Unix epoch in seconds for the auction start time
     @param _endTimestamp Unix epoch in seconds for the auction end time.
     */
    function batchCreateAuctions(
        uint256[] calldata _tokenIds,
        uint256 _reservePrice,
        uint256 _startTimestamp,
        uint256 _endTimestamp
    ) external onlyOwner {
        require(_tokenIds.length > 0, "Invalid token ids");
        // Check owner of the token is the creator and approved
        for(uint i=0; i<_tokenIds.length; i++) {
            require(
                nftToken.isApprovedForAll(nftToken.ownerOf(_tokenIds[i]), address(this)),
                "Not approved"
            );

            _createAuction(
                _tokenIds[i],
                _reservePrice,
                _startTimestamp,
                _endTimestamp
            );
        }
    }

    /**
     @notice Creates a new auction for a given nft
     @dev Only the owner of a nft can create an auction and must have approved the contract
     @dev End time for the auction must be in the future.
     @param _tokenId Token ID of the nft being auctioned
     @param _reservePrice Nft cannot be sold for less than this or minBidIncrement, whichever is higher
     @param _startTimestamp Unix epoch in seconds for the auction start time
     @param _endTimestamp Unix epoch in seconds for the auction end time.
     */
    function createAuction(
        uint256 _tokenId,
        uint256 _reservePrice,
        uint256 _startTimestamp,
        uint256 _endTimestamp
    ) external onlyOwner {
        // Check owner of the token is the creator and approved
        require(
            nftToken.isApprovedForAll(nftToken.ownerOf(_tokenId), address(this)),
            "Not approved"
        );

        _createAuction(
            _tokenId,
            _reservePrice,
            _startTimestamp,
            _endTimestamp
        );
    }


    /**
     @notice Places a new bid, out bidding the existing bidder if found and criteria is reached
     @dev Only callable when the auction is open
     @dev Bids from smart contracts are prohibited to prevent griefing with always reverting receiver
     @param _tokenId Token ID of the NFT being auctioned
     @param _amount Bid STARL amount
     */
    function placeBid(uint256 _tokenId, uint256 _amount) external payable {
        require(_msgSender().isContract() == false, "No contracts permitted");

        // Check the auction to see if this is a valid bid
        Auction storage auction = auctions[_tokenId];

        // Ensure auction is in flight
        require(
            _getNow() >= auction.startTime && _getNow() <= auction.endTime,
            "Bidding outside of the auction window"
        );

        // Ensure bid adheres to outbid increment and threshold
        HighestBid storage highestBid = highestBids[_tokenId];
        uint256 minBidRequired = highestBid.bid.add(minBidIncrement);
        require(_amount >= auction.reservePrice, "Failed to outbid min bid price");
        require(_amount >= minBidRequired, "Failed to outbid highest bidder");

        // Transfer STARL token
        token.safeTransferFrom(_msgSender(), address(this), _amount);

        // Refund existing top bidder if found
        if (highestBid.bidder != address(0)) {
            _refundHighestBidder(highestBid.bidder, highestBid.bid);
        }

        // assign top bidder and bid time
        highestBid.bidder = _msgSender();
        highestBid.bid = _amount;
        highestBid.lastBidTime = _getNow();

        emit BidPlaced(_tokenId, _msgSender(), _amount);
    }

    /**
     @notice Given a sender who has the highest bid on a NFT, allows them to withdraw their bid
     @dev Only callable by the existing top bidder
     @param _tokenId Token ID of the NFT being auctioned
     */
    function withdrawBid(uint256 _tokenId) external {
        HighestBid storage highestBid = highestBids[_tokenId];

        // Ensure highest bidder is the caller
        require(highestBid.bidder == _msgSender(), "You are not the highest bidder");

        // Check withdrawal after delay time
        require(
            _getNow() >= highestBid.lastBidTime.add(bidWithdrawalLockTime),
            "Cannot withdraw until lock time has passed"
        );

        require(_getNow() < auctions[_tokenId].endTime, "Past auction end");

        uint256 previousBid = highestBid.bid;

        // Clean up the existing top bid
        delete highestBids[_tokenId];

        // Refund the top bidder
        _refundHighestBidder(_msgSender(), previousBid);

        emit BidWithdrawn(_tokenId, _msgSender(), previousBid);
    }


    //////////
    // Admin /
    //////////

    /**
     @notice Results a finished auction
     @dev Only admin or smart contract
     @dev Auction can only be resulted if there has been a bidder and reserve met.
     @dev If there have been no bids, the auction needs to be cancelled instead using `cancelAuction()`
     @param _tokenId Token ID of the NFT being auctioned
     */
    function resultAuction(uint256 _tokenId) external onlyOwner {

        // Check the auction to see if it can be resulted
        Auction storage auction = auctions[_tokenId];

        // Check the auction real
        require(auction.endTime > 0, "Auction does not exist");

        // Check the auction has ended
        require(_getNow() > auction.endTime, "The auction has not ended");

        // Ensure auction not already resulted
        require(!auction.resulted, "auction already resulted");

        // Ensure this contract is approved to move the token
        require(nftToken.isApprovedForAll(nftToken.ownerOf(_tokenId), address(this)), "auction not approved");

        // Get info on who the highest bidder is
        HighestBid storage highestBid = highestBids[_tokenId];
        address winner = highestBid.bidder;
        uint256 winningBid = highestBid.bid;

        // Ensure auction not already resulted
        require(winningBid >= auction.reservePrice, "reserve not reached");

        // Ensure there is a winner
        require(winner != address(0), "no open bids");

        // Result the auction
        auctions[_tokenId].resulted = true;

        // Clean up the highest bid
        delete highestBids[_tokenId];

        // Send token to devs
        token.safeTransfer(devFeeRecipient, winningBid);

        // Transfer the token to the winner
        nftToken.safeTransferFrom(nftToken.ownerOf(_tokenId), winner, _tokenId);

        emit AuctionResulted(_tokenId, winner, winningBid);
    }

    /**
     @notice Cancels and inflight and un-resulted auctions, returning the funds to the top bidder if found
     @dev Only admin
     @param _tokenId Token ID of the NFT being auctioned
     */
    function cancelAuction(uint256 _tokenId) external onlyOwner {

        // Check valid and not resulted
        Auction storage auction = auctions[_tokenId];

        // Check auction is real
        require(auction.endTime > 0, "Auction does not exist");

        // Check auction not already resulted
        require(!auction.resulted, "Auction already resulted");

        // refund existing top bidder if found
        HighestBid storage highestBid = highestBids[_tokenId];
        if (highestBid.bidder != address(0)) {
            _refundHighestBidder(highestBid.bidder, highestBid.bid);

            // Clear up highest bid
            delete highestBids[_tokenId];
        }

        // Remove auction and top bidder
        delete auctions[_tokenId];

        emit AuctionCancelled(_tokenId);
    }

    /**
     @notice Update the amount by which bids have to increase, across all auctions
     @dev Only admin
     @param _minBidIncrement New bid step in WEI
     */
    function updateMinBidIncrement(uint256 _minBidIncrement) external onlyOwner {
        minBidIncrement = _minBidIncrement;
        emit UpdateMinBidIncrement(_minBidIncrement);
    }

    /**
     @notice Update the global bid withdrawal lockout time
     @dev Only admin
     @param _bidWithdrawalLockTime New bid withdrawal lock time
     */
    function updateBidWithdrawalLockTime(uint256 _bidWithdrawalLockTime) external onlyOwner {
        bidWithdrawalLockTime = _bidWithdrawalLockTime;
        emit UpdateBidWithdrawalLockTime(_bidWithdrawalLockTime);
    }

    /**
     @notice Update the current reserve price for an auction
     @dev Only admin
     @dev Auction must exist
     @param _tokenId Token ID of the NFT being auctioned
     @param _reservePrice New Ether reserve price (WEI value)
     */
    function updateAuctionReservePrice(uint256 _tokenId, uint256 _reservePrice) external onlyOwner {
        require(
            auctions[_tokenId].endTime > 0,
            "No Auction exists"
        );

        auctions[_tokenId].reservePrice = _reservePrice;
        emit UpdateAuctionReservePrice(_tokenId, _reservePrice);
    }

    /**
     @notice Update the current start time for an auction
     @dev Only admin
     @dev Auction must exist
     @param _tokenId Token ID of the NFT being auctioned
     @param _startTime New start time (unix epoch in seconds)
     */
    function updateAuctionStartTime(uint256 _tokenId, uint256 _startTime) external onlyOwner {
        require(
            auctions[_tokenId].endTime > 0,
            "No Auction exists"
        );

        auctions[_tokenId].startTime = _startTime;
        emit UpdateAuctionStartTime(_tokenId, _startTime);
    }

    /**
     @notice Update the current end time for an auction
     @dev Only admin
     @dev Auction must exist
     @param _tokenId Token ID of the NFT being auctioned
     @param _endTimestamp New end time (unix epoch in seconds)
     */
    function updateAuctionEndTime(uint256 _tokenId, uint256 _endTimestamp) external onlyOwner {
        require(
            auctions[_tokenId].endTime > 0,
            "No Auction exists"
        );
        require(
            auctions[_tokenId].startTime < _endTimestamp,
            "End time must be greater than start"
        );
        require(
            _endTimestamp > _getNow(),
            "End time passed. Nobody can bid"
        );

        auctions[_tokenId].endTime = _endTimestamp;
        emit UpdateAuctionEndTime(_tokenId, _endTimestamp);
    }


    ///////////////
    // Accessors //
    ///////////////

    /**
     @notice Method for getting all info about the auction
     @param _tokenId Token ID of the NFT being auctioned
     */
    function getAuction(uint256 _tokenId)
    external
    view
    returns (uint256 _reservePrice, uint256 _startTime, uint256 _endTime, bool _resulted) {
        Auction storage auction = auctions[_tokenId];
        return (
            auction.reservePrice,
            auction.startTime,
            auction.endTime,
            auction.resulted
        );
    }

    /**
     @notice Method for getting all info about the highest bidder
     @param _tokenId Token ID of the NFT being auctioned
     */
    function getHighestBidder(uint256 _tokenId) external view returns (
        address payable _bidder,
        uint256 _bid,
        uint256 _lastBidTime
    ) {
        HighestBid storage highestBid = highestBids[_tokenId];
        return (
            highestBid.bidder,
            highestBid.bid,
            highestBid.lastBidTime
        );
    }


    /////////////////////////
    // Internal and Private /
    /////////////////////////

    function _getNow() internal virtual view returns (uint256) {
        return block.timestamp;
    }

    /**
     @notice Private method doing the heavy lifting of creating an auction
     @param _tokenId Token ID of the nft being auctioned
     @param _reservePrice Nft cannot be sold for less than this or minBidIncrement, whichever is higher
     @param _startTimestamp Unix epoch in seconds for the auction start time
     @param _endTimestamp Unix epoch in seconds for the auction end time.
     */
    function _createAuction(
        uint256 _tokenId,
        uint256 _reservePrice,
        uint256 _startTimestamp,
        uint256 _endTimestamp
    ) private {
        // Ensure a token cannot be re-listed if previously successfully sold
        require(auctions[_tokenId].endTime == 0, "Cannot relist");

        // Check end time not before start time and that end is in the future
        require(_endTimestamp > _startTimestamp, "End time must be greater than start");
        require(_endTimestamp > _getNow(), "End time passed. Nobody can bid.");

        // Setup the auction
        auctions[_tokenId] = Auction({
            reservePrice : _reservePrice,
            startTime : _startTimestamp,
            endTime : _endTimestamp,
            resulted : false
        });

        emit AuctionCreated(_tokenId, _reservePrice, _startTimestamp, _endTimestamp);
    }

    /**
     @notice Used for sending back escrowed funds from a previous bid
     @param _currentHighestBidder Address of the last highest bidder
     @param _currentHighestBid STARL amount that the bidder sent when placing their bid
     */
    function _refundHighestBidder(address payable _currentHighestBidder, uint256 _currentHighestBid) private {
        token.safeTransfer(_currentHighestBidder, _currentHighestBid);
        emit BidRefunded(_currentHighestBidder, _currentHighestBid);
    }
}