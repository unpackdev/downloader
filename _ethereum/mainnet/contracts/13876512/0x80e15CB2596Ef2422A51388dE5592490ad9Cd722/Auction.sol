// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./FarbeArt.sol";
import "./SaleBase.sol";


/**
 * @title Base auction contract
 * @dev This is the base auction contract which implements the auction functionality
 */
contract AuctionBase is SaleBase {
    using Address for address payable;

    // auction struct to keep track of the auctions
    struct Auction {
        address seller;
        address creator;
        address gallery;
        address buyer;
        uint128 currentPrice;
        uint64 duration;
        uint64 startedAt;
        uint16 creatorCut;
        uint16 platformCut;
        uint16 galleryCut;
    }

    // mapping for tokenId to its auction
    mapping(uint256 => Auction) tokenIdToAuction;

    event AuctionCreated(uint256 tokenId, uint256 startingPrice, uint256 duration);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);

    /**
     * @dev Add the auction to the mapping and emit the AuctionCreated event, duration must meet the requirements
     * @param _tokenId ID of the token to auction
     * @param _auction Reference to the auction struct to add to the mapping
     */
    function _addAuction(uint256 _tokenId, Auction memory _auction) internal {
        // check minimum and maximum time requirements
        require(_auction.duration >= 1 hours && _auction.duration <= 30 days, "time requirement failed");

        // update mapping
        tokenIdToAuction[_tokenId] = _auction;

        // emit event
        emit AuctionCreated(
            uint256(_tokenId),
            uint256(_auction.currentPrice),
            uint256(_auction.duration)
        );
    }

    /**
     * @dev Remove the auction from the mapping (sets everything to zero/false)
     * @param _tokenId ID of the token to remove auction of
     */
    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

    /**
     * @dev Internal function to check the current price of the auction
     * @param auction Reference to the auction to check price of
     * @return uint128 The current price of the auction
     */
    function _currentPrice(Auction storage auction) internal view returns (uint128) {
        return (auction.currentPrice);
    }

    /**
     * @dev Internal function to return the bid to the previous bidder if there was one
     * @param _destination Address of the previous bidder
     * @param _amount Amount to return to the previous bidder
     */
    function _returnBid(address payable _destination, uint256 _amount) private {
        // zero address means there was no previous bidder
        if (_destination != address(0)) {
            _destination.sendValue(_amount);
        }
    }

    /**
     * @dev Internal function to check if an auction started. By default startedAt is at 0
     * @param _auction Reference to the auction struct to check
     * @return bool Weather the auction has started
     */
    function _isOnAuction(Auction storage _auction) internal view returns (bool) {
        return (_auction.startedAt > 0 && _auction.startedAt <= block.timestamp);
    }

    /**
     * @dev Internal function to implement the bid functionality
     * @param _tokenId ID of the token to bid upon
     * @param _bidAmount Amount to bid
     */
    function _bid(uint _tokenId, uint _bidAmount) internal {
        // get reference to the auction struct
        Auction storage auction = tokenIdToAuction[_tokenId];

        // check if the item is on auction
        require(_isOnAuction(auction), "Item is not on auction");

        // check if auction time has ended
        uint256 secondsPassed = block.timestamp - auction.startedAt;
        require(secondsPassed <= auction.duration, "Auction time has ended");

        // check if bid is higher than the previous one
        uint256 price = auction.currentPrice;
        require(_bidAmount > price, "Bid is too low");

        // return the previous bidder's bid amount
        _returnBid(payable(auction.buyer), auction.currentPrice);

        // update the current bid amount and the bidder address
        auction.currentPrice = uint128(_bidAmount);
        auction.buyer = msg.sender;

        // if the bid is made in the last 15 minutes, increase the duration of the
        // auction so that the timer resets to 15 minutes
        uint256 timeRemaining = auction.duration - secondsPassed;
        if (timeRemaining <= 15 minutes) {
            uint256 timeToAdd = 15 minutes - timeRemaining;
            auction.duration += uint64(timeToAdd);
        }
    }

    /**
     * @dev Internal function to finish the auction after the auction time has ended
     * @param _tokenId ID of the token to finish auction of
     */
    function _finishAuction(uint256 _tokenId) internal {
        // using storage for _isOnAuction
        Auction storage auction = tokenIdToAuction[_tokenId];

        // check if token was on auction
        require(_isOnAuction(auction), "Token was not on auction");

        // check if auction time has ended
        uint256 secondsPassed = block.timestamp - auction.startedAt;
        require(secondsPassed > auction.duration, "Auction hasn't ended");

        // using struct to avoid stack too deep error
        Auction memory referenceAuction = auction;

        // delete the auction
        _removeAuction(_tokenId);

        // if there was no successful bid, return token to the seller
        if (referenceAuction.buyer == address(0)) {
            _transfer(referenceAuction.seller, _tokenId);

            emit AuctionSuccessful(
                _tokenId,
                0,
                referenceAuction.seller
            );
        }
        // if there was a successful bid, pay the seller and transfer the token to the buyer
        else {
            _payout(
                payable(referenceAuction.seller),
                payable(referenceAuction.creator),
                payable(referenceAuction.gallery),
                referenceAuction.creatorCut,
                referenceAuction.platformCut,
                referenceAuction.galleryCut,
                referenceAuction.currentPrice,
                _tokenId
            );
            _transfer(referenceAuction.buyer, _tokenId);

            emit AuctionSuccessful(
                _tokenId,
                referenceAuction.currentPrice,
                referenceAuction.buyer
            );
        }
    }

    /**
     * @dev This is an internal function to end auction meant to only be used as a safety
     * mechanism if an NFT got locked within the contract. Can only be called by the super admin
     * after a period f 7 days has passed since the auction ended
     * @param _tokenId Id of the token to end auction of
     * @param _nftBeneficiary Address to send the NFT to
     * @param _paymentBeneficiary Address to send the payment to
     */
    function _forceFinishAuction(
        uint256 _tokenId,
        address _nftBeneficiary,
        address _paymentBeneficiary
    )
    internal
    {
        // using storage for _isOnAuction
        Auction storage auction = tokenIdToAuction[_tokenId];

        // check if token was on auction
        require(_isOnAuction(auction), "Token was not on auction");

        // check if auction time has ended
        uint256 secondsPassed = block.timestamp - auction.startedAt;
        require(secondsPassed > auction.duration, "Auction hasn't ended");

        // check if its been more than 7 days since auction ended
        require(secondsPassed - auction.duration >= 7 days);

        // using struct to avoid stack too deep error
        Auction memory referenceAuction = auction;

        // delete the auction
        _removeAuction(_tokenId);

        // transfer ether to the beneficiary
        payable(_paymentBeneficiary).sendValue(referenceAuction.currentPrice);

        // transfer nft to the nft beneficiary
        _transfer(_nftBeneficiary, _tokenId);
    }
}


/**
 * @title Auction sale contract that provides external functions
 * @dev Implements the external and public functions of the auction implementation
 */
contract AuctionSale is AuctionBase {
    // sanity check for the nft contract
    bool public isFarbeSaleAuction = true;

    // ERC721 interface id
    bytes4 constant InterfaceSignature_ERC721 = bytes4(0x80ac58cd);

    constructor(address _nftAddress, address _platformAddress) {
        // check NFT contract supports ERC721 interface
        FarbeArtSale candidateContract = FarbeArtSale(_nftAddress);
        require(candidateContract.supportsInterface(InterfaceSignature_ERC721));

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        platformWalletAddress = _platformAddress;

        NFTContract = candidateContract;
    }

    /**
     * @dev External function to create auction. Called by the Farbe NFT contract
     * @param _tokenId ID of the token to create auction for
     * @param _startingPrice Starting price of the auction in wei
     * @param _duration Duration of the auction in seconds
     * @param _creator Address of the original creator of the NFT
     * @param _seller Address of the seller of the NFT
     * @param _gallery Address of the gallery of this auction, will be 0 if no gallery is involved
     * @param _creatorCut The cut that goes to the creator, as %age * 10
     * @param _galleryCut The cut that goes to the gallery, as %age * 10
     * @param _platformCut The cut that goes to the platform if it is a primary sale
     */
    function createSale(
        uint256 _tokenId,
        uint128 _startingPrice,
        uint64 _startingTime,
        uint64 _duration,
        address _creator,
        address _seller,
        address _gallery,
        uint16 _creatorCut,
        uint16 _galleryCut,
        uint16 _platformCut
    )
    external
    onlyFarbeContract
    {
        // create and add the auction
        Auction memory auction = Auction(
            _seller,
            _creator,
            _gallery,
            address(0),
            uint128(_startingPrice),
            uint64(_duration),
            _startingTime,
            _creatorCut,
            _platformCut,
            _galleryCut
        );
        _addAuction(_tokenId, auction);
    }

    /**
     * @dev External payable bid function. Sellers can not bid on their own artworks
     * @param _tokenId ID of the token to bid on
     */
    function bid(uint256 _tokenId) external payable {
        // do not allow sellers and galleries to bid on their own artwork
        require(tokenIdToAuction[_tokenId].seller != msg.sender && tokenIdToAuction[_tokenId].gallery != msg.sender,
            "Sellers and Galleries not allowed");

        _bid(_tokenId, msg.value);
    }

    /**
     * @dev External function to finish the auction. Currently can be called by anyone TODO restrict access?
     * @param _tokenId ID of the token to finish auction of
     */
    function finishAuction(uint256 _tokenId) external {
        _finishAuction(_tokenId);
    }

    /**
     * @dev External view function to get the details of an auction
     * @param _tokenId ID of the token to get the auction information of
     * @return seller Address of the seller
     * @return buyer Address of the buyer
     * @return currentPrice Current Price of the auction in wei
     * @return duration Duration of the auction in seconds
     * @return startedAt Unix timestamp for when the auction started
     */
    function getAuction(uint256 _tokenId)
    external
    view
    returns
    (
        address seller,
        address buyer,
        uint256 currentPrice,
        uint256 duration,
        uint256 startedAt
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return (
        auction.seller,
        auction.buyer,
        auction.currentPrice,
        auction.duration,
        auction.startedAt
        );
    }

    /**
     * @dev External view function to get the current price of an auction
     * @param _tokenId ID of the token to get the current price of
     * @return uint128 Current price of the auction in wei
     */
    function getCurrentPrice(uint256 _tokenId)
    external
    view
    returns (uint128)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }

    /**
     * @dev Helper function for testing with timers TODO Remove this before deploying live
     * @param _tokenId ID of the token to get timers of
     */
    function getTimers(uint256 _tokenId)
    external
    view returns (
        uint256 saleStart,
        uint256 blockTimestamp,
        uint256 duration
    ) {
        Auction memory auction = tokenIdToAuction[_tokenId];
        return (auction.startedAt, block.timestamp, auction.duration);
    }

    /**
     * @dev This is an internal function to end auction meant to only be used as a safety
     * mechanism if an NFT got locked within the contract. Can only be called by the super admin
     * after a period f 7 days has passed since the auction ended
     * @param _tokenId Id of the token to end auction of
     * @param _nftBeneficiary Address to send the NFT to
     * @param _paymentBeneficiary Address to send the payment to
     */
    function forceFinishAuction(
        uint256 _tokenId,
        address _nftBeneficiary,
        address _paymentBeneficiary
    )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _forceFinishAuction(_tokenId, _nftBeneficiary, _paymentBeneficiary);
    }
}