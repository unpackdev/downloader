// SPDX-License-Identifier: Unlicense
// moved from https://github.com/museum-of-war/auction
pragma solidity 0.8.13;

import "IERC721.sol";
import "Ownable.sol";
import "IWithBalance.sol";

/// @title An Auction Contract for bidding single NFTs (modified contract of Avo Labs GmbH)
/// @notice This contract can be used for auctioning any NFTs
contract NFTAuctionV2 is Ownable {
    address[] public whitelistedPassCollections; //Only owners of tokens from any of these collections can make bids if is onlyWhitelisted
    mapping(address => mapping(uint256 => Auction)) public nftContractAuctions;
    mapping(address => uint256) failedTransferCredits;
    //Each Auction is unique to each NFT (contract + id pairing).
    struct Auction {
        //map token ID to
        uint32 bidIncreasePercentage;
        uint32 auctionBidPeriod; //Increments the length of time the auction is open in which a new bid can be made after each bid.
        uint64 auctionStart;
        uint64 auctionEnd;
        uint128 minPrice;
        uint128 nftHighestBid;
        address nftHighestBidder;
        address feeRecipient;
        bool onlyWhitelisted; // if true, than only owners of whitelistedPassCollections can make bids
    }
    /*
     * Default values that are used if not specified by the NFT seller.
     */
    uint32 public constant defaultBidIncreasePercentage = 100; // 1.00%
    uint32 public constant defaultAuctionBidPeriod = 43200; //12 hours

    /*╔═════════════════════════════╗
      ║           EVENTS            ║
      ╚═════════════════════════════╝*/

    event NftAuctionCreated(
        address indexed nftContractAddress,
        uint256 indexed tokenId,
        uint128 minPrice,
        uint64 auctionStart,
        uint64 auctionEnd,
        uint32 auctionBidPeriod,
        uint32 bidIncreasePercentage,
        address feeRecipient,
        bool onlyWhitelisted
    );

    event BidMade(
        address indexed nftContractAddress,
        uint256 indexed tokenId,
        address bidder,
        uint256 ethAmount
    );

    event AuctionPeriodUpdated(
        address indexed nftContractAddress,
        uint256 indexed tokenId,
        uint64 auctionEndPeriod
    );

    event NFTTransferredAndSellerPaid(
        address indexed nftContractAddress,
        uint256 indexed tokenId,
        uint128 nftHighestBid,
        address nftHighestBidder
    );

    event AuctionSettled(
        address indexed nftContractAddress,
        uint256 indexed tokenId
    );

    event AuctionWithdrawn(
        address indexed nftContractAddress,
        uint256 indexed tokenId
    );

    event HighestBidTaken(address indexed nftContractAddress, uint256 indexed tokenId);
    /**********************************/
    /*╔═════════════════════════════╗
      ║             END             ║
      ║            EVENTS           ║
      ╚═════════════════════════════╝*/
    /**********************************/
    /*╔═════════════════════════════╗
      ║          MODIFIERS          ║
      ╚═════════════════════════════╝*/

    modifier needWhitelistedToken(address _nftContractAddress, uint256 _tokenId) {
        if (nftContractAuctions[_nftContractAddress][_tokenId].onlyWhitelisted) {
            bool isWhitelisted;
            for (uint256 i = 0; i < whitelistedPassCollections.length; i++) {
                if(IWithBalance(whitelistedPassCollections[i]).balanceOf(msg.sender) > 0) {
                    isWhitelisted = true;
                    break;
                }
            }
            require(isWhitelisted, "Sender has no whitelisted NFTs");
        }
        _;
    }

    modifier auctionOngoing(address _nftContractAddress, uint256 _tokenId) {
        require(
            _isAuctionStarted(_nftContractAddress, _tokenId),
            "Auction has not started"
        );
        require(
            _isAuctionOngoing(_nftContractAddress, _tokenId),
            "Auction has ended"
        );
        _;
    }

    /*
     * The bid amount must be higher than the previous
     * bid by the specified bid increase percentage.
     */
    modifier bidAmountMeetsBidRequirements(
        address _nftContractAddress,
        uint256 _tokenId
    ) {
        require(
            _doesBidMeetBidRequirements(
                _nftContractAddress,
                _tokenId
            ),
            "Not enough funds to bid on NFT"
        );
        _;
    }

    modifier notZeroAddress(address _address) {
        require(_address != address(0), "Cannot specify 0 address");
        _;
    }

    /**********************************/
    /*╔═════════════════════════════╗
      ║             END             ║
      ║          MODIFIERS          ║
      ╚═════════════════════════════╝*/
    /**********************************/
    // constructor
    constructor(address[] memory _whitelistedPassCollectionsAddresses) {
        uint256 collectionsCount = _whitelistedPassCollectionsAddresses.length;
        for (uint256 i = 0; i < collectionsCount; i++) {
            whitelistedPassCollections.push(_whitelistedPassCollectionsAddresses[i]);
        }
    }
    /**********************************/
    /*╔══════════════════════════════╗
      ║     WHITELIST FUNCTIONS      ║
      ╚══════════════════════════════╝*/
    /*
     * Add whitelisted pass collection.
     */
    function addWhitelistedCollection(address _collectionContractAddress)
        external
        onlyOwner
    {
        whitelistedPassCollections.push(_collectionContractAddress);
    }

    /*
     * Remove whitelisted pass collection by index.
     */
    function removeWhitelistedCollection(uint256 index)
        external
        onlyOwner
    {
        whitelistedPassCollections[index] = whitelistedPassCollections[whitelistedPassCollections.length - 1];
        whitelistedPassCollections.pop();
    }
    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║     WHITELIST FUNCTIONS      ║
      ╚══════════════════════════════╝*/
    /**********************************/
    /*╔══════════════════════════════╗
      ║    AUCTION CHECK FUNCTIONS   ║
      ╚══════════════════════════════╝*/
    function _isAuctionStarted(address _nftContractAddress, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        uint64 auctionStartTimestamp = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].auctionStart;
        return (block.timestamp >= auctionStartTimestamp);
    }

    function _isAuctionOngoing(address _nftContractAddress, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        uint64 auctionEndTimestamp = nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd;
        //if the auctionEnd is set to 0, the auction is technically on-going, however
        //the minimum bid price (minPrice) has not yet been met.
        return (auctionEndTimestamp == 0 ||
            block.timestamp < auctionEndTimestamp);
    }

    /*
     * Check that a bid is applicable for the purchase of the NFT.
     * The bid needs to be a % higher than the previous bid.
     */
    function _doesBidMeetBidRequirements(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal view returns (bool) {
        uint256 highestBid = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid;
        if (highestBid > 0) {
            //if the NFT is up for auction, the bid needs to be a % higher than the previous bid
            uint256 bidIncreaseAmount = (highestBid *
            (10000 +
            _getBidIncreasePercentage(_nftContractAddress, _tokenId))) /
            10000;
            return msg.value >= bidIncreaseAmount;
        } else {
            return msg.value >= nftContractAuctions[_nftContractAddress][_tokenId].minPrice;
        }
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║    AUCTION CHECK FUNCTIONS   ║
      ╚══════════════════════════════╝*/
    /**********************************/
    /*╔══════════════════════════════╗
      ║    DEFAULT GETTER FUNCTIONS  ║
      ╚══════════════════════════════╝*/
    /*****************************************************************
     * These functions check if the applicable auction parameter has *
     * been set by the NFT seller. If not, return the default value. *
     *****************************************************************/

    function _getBidIncreasePercentage(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal view returns (uint32) {
        uint32 bidIncreasePercentage = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].bidIncreasePercentage;

        if (bidIncreasePercentage == 0) {
            return defaultBidIncreasePercentage;
        } else {
            return bidIncreasePercentage;
        }
    }

    function _getAuctionBidPeriod(address _nftContractAddress, uint256 _tokenId)
        internal
        view
        returns (uint32)
    {
        uint32 auctionBidPeriod = nftContractAuctions[_nftContractAddress][_tokenId].auctionBidPeriod;

        if (auctionBidPeriod == 0) {
            return defaultAuctionBidPeriod;
        } else {
            return auctionBidPeriod;
        }
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║    DEFAULT GETTER FUNCTIONS  ║
      ╚══════════════════════════════╝*/
    /**********************************/

    /*╔══════════════════════════════╗
      ║       AUCTION CREATION       ║
      ╚══════════════════════════════╝*/

    function createNewNftAuctions(
        address _nftContractAddress,
        uint256[] memory _tokenIds,
        uint32 _bidIncreasePercentage,
        uint32 _auctionBidPeriod,
        uint64 _auctionStart,
        uint64 _auctionEnd,
        uint128 _minPrice,
        address _feeRecipient,
        bool _onlyWhitelisted
    )
        external
        onlyOwner
        notZeroAddress(_feeRecipient)
    {
        require(_auctionEnd >= _auctionStart, "Auction end must be after the start");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];

            require(
                nftContractAuctions[_nftContractAddress][_tokenId].feeRecipient == address(0),
                "Auction is already created"
            );

            Auction memory auction; // creating auction
            auction.bidIncreasePercentage = _bidIncreasePercentage;
            auction.auctionBidPeriod = _auctionBidPeriod;
            auction.auctionStart = _auctionStart;
            auction.auctionEnd = _auctionEnd;
            auction.minPrice = _minPrice;
            auction.feeRecipient = _feeRecipient;
            auction.onlyWhitelisted = _onlyWhitelisted;

            nftContractAuctions[_nftContractAddress][_tokenId] = auction;

            // Sending the NFT to this contract
            if (IERC721(_nftContractAddress).ownerOf(_tokenId) == msg.sender) {
                IERC721(_nftContractAddress).transferFrom(
                    msg.sender,
                    address(this),
                    _tokenId
                );
            }
            require(
                IERC721(_nftContractAddress).ownerOf(_tokenId) == address(this),
                "NFT transfer failed"
            );

            uint32 _selectedAuctionBidPeriod = _auctionBidPeriod > 0 ? _auctionBidPeriod : defaultAuctionBidPeriod;
            uint32 _selectedBidIncreasePercentage = _bidIncreasePercentage > 0 ? _bidIncreasePercentage : defaultBidIncreasePercentage;

            emit NftAuctionCreated(
                _nftContractAddress,
                _tokenId,
                _minPrice,
                _auctionStart,
                _auctionEnd,
                _selectedAuctionBidPeriod,
                _selectedBidIncreasePercentage,
                _feeRecipient,
                _onlyWhitelisted
            );
        }
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║       AUCTION CREATION       ║
      ╚══════════════════════════════╝*/
    /**********************************/

    /*╔═════════════════════════════╗
      ║        BID FUNCTIONS        ║
      ╚═════════════════════════════╝*/

    /********************************************************************
     *                          Make bids with ETH.                     *
     ********************************************************************/

    function makeBid(
        address _nftContractAddress,
        uint256 _tokenId
    )
        external
        payable
        auctionOngoing(_nftContractAddress, _tokenId)
        needWhitelistedToken(
            _nftContractAddress,
            _tokenId
        )
        bidAmountMeetsBidRequirements(
            _nftContractAddress,
            _tokenId
        )
    {
        require(msg.sender == tx.origin, "Sender must be a wallet");
        require(
            nftContractAuctions[_nftContractAddress][_tokenId].feeRecipient != address(0),
            "Auction does not exist"
        );

        // Reverse previous bid and update highest bid:
        address prevNftHighestBidder = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder;
        uint256 prevNftHighestBid = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid;

        // update highest bid
        nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid = uint128(msg.value);
        nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder = msg.sender;

        if (prevNftHighestBidder != address(0)) { // payout if needed
            _payout(prevNftHighestBidder, prevNftHighestBid);
        }

        emit BidMade(
            _nftContractAddress,
            _tokenId,
            msg.sender,
            msg.value
        );

        // Update auction end if needed:
        //the auction end is set to now + the bid period if it is greater than the previous one
        uint64 newEnd = _getAuctionBidPeriod(_nftContractAddress, _tokenId) + uint64(block.timestamp);
        if (newEnd > nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd) {
            nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd = newEnd;
            emit AuctionPeriodUpdated(
                _nftContractAddress,
                _tokenId,
                nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd
            );
        }
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║        BID FUNCTIONS         ║
      ╚══════════════════════════════╝*/
    /**********************************/

    /*╔══════════════════════════════╗
      ║  TRANSFER NFT & PAY SELLER   ║
      ╚══════════════════════════════╝*/
    function _transferNftAndPaySeller(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        address _feeRecipient = nftContractAuctions[_nftContractAddress][_tokenId].feeRecipient;
        address _nftHighestBidder = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder;
        uint128 _nftHighestBid = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid;

        nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder = address(0);
        nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid = 0;

        _payout(_feeRecipient, _nftHighestBid);
        IERC721(_nftContractAddress).transferFrom(
            address(this),
            _nftHighestBidder,
            _tokenId
        );

        delete nftContractAuctions[_nftContractAddress][_tokenId];
        emit NFTTransferredAndSellerPaid(
            _nftContractAddress,
            _tokenId,
            _nftHighestBid,
            _nftHighestBidder
        );
    }

    function _payout(address _recipient, uint256 _amount) internal {
        // attempt to send the funds to the recipient
        (bool success, ) = payable(_recipient).call{ value: _amount, gas: 20000 }("");
        // if it failed, update their credit balance so they can pull it later
        if (!success) failedTransferCredits[_recipient] = failedTransferCredits[_recipient] + _amount;
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║  TRANSFER NFT & PAY SELLER   ║
      ╚══════════════════════════════╝*/
    /**********************************/

    /*╔══════════════════════════════╗
      ║      SETTLE & WITHDRAW       ║
      ╚══════════════════════════════╝*/
    function settleAuctions(address _nftContractAddress, uint256[] memory _tokenIds)
        external
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            address _nftHighestBidder = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder;
            if (!_isAuctionOngoing(_nftContractAddress, _tokenId) && _nftHighestBidder != address(0)) {
                _transferNftAndPaySeller(_nftContractAddress, _tokenId);
                emit AuctionSettled(_nftContractAddress, _tokenId);
            }
        }
    }

    function withdrawAuctions(address _nftContractAddress, uint256[] memory _tokenIds)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            address _nftHighestBidder = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder;
            if (_nftHighestBidder != address(0)) {
                uint128 _nftHighestBid = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid;
                _payout(_nftHighestBidder, _nftHighestBid);
            }
            delete nftContractAuctions[_nftContractAddress][_tokenId];
            IERC721(_nftContractAddress).transferFrom(
                address(this),
                owner(),
                _tokenId
            );
            emit AuctionWithdrawn(_nftContractAddress, _tokenId);
        }
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║      SETTLE & WITHDRAW       ║
      ╚══════════════════════════════╝*/
    /**********************************/

    /*╔══════════════════════════════╗
      ║       UPDATE AUCTION         ║
      ╚══════════════════════════════╝*/

    /*
     * The NFT seller can opt to end an auction by taking the current highest bid.
     */
    function takeHighestBids(address _nftContractAddress, uint256[] memory _tokenIds)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            if (nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid > 0) {
                _transferNftAndPaySeller(_nftContractAddress, _tokenId);
                emit HighestBidTaken(_nftContractAddress, _tokenId);
            } else {
                IERC721(_nftContractAddress).transferFrom(
                    address(this),
                    msg.sender,
                    _tokenId
                );
                delete nftContractAuctions[_nftContractAddress][_tokenId];
            }
        }
    }

    /*
     * If the transfer of a bid has failed, allow to reclaim amount later.
     */
    function withdrawAllFailedCreditsOf(address recipient) external {
        uint256 amount = failedTransferCredits[recipient];

        require(amount != 0, "no credits to withdraw");

        failedTransferCredits[recipient] = 0;

        (bool successfulWithdraw, ) = recipient.call{
            value: amount,
            gas: 20000
        }("");
        require(successfulWithdraw, "withdraw failed");
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║       UPDATE AUCTION         ║
      ╚══════════════════════════════╝*/
    /**********************************/
}
