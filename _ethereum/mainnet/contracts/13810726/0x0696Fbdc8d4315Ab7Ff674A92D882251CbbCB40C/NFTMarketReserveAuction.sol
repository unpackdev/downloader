// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity 0.8.4;
pragma abicoder v2; // solhint-disable-line

import "./SafeMathUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./Constants.sol";
import "./SendValueWithFallbackWithdraw.sol";
import "./NFTMarketAuction.sol";
import "./WethioAdminRole.sol";

/**
 * @notice Manages a reserve price auction for NFTs.
 */
abstract contract NFTMarketReserveAuction is
    Constants,
    WethioAdminRole,
    ReentrancyGuardUpgradeable,
    SendValueWithFallbackWithdraw,
    NFTMarketAuction
{
    using SafeMathUpgradeable for uint256;

    struct ReserveAuction {
        address nftContract;
        uint256[] tokenId;
        address seller;
        uint256 duration;
        uint256 extensionDuration;
        uint256 endTime;
        address bidder;
        uint256 amount;
        bool canAuction;
    }

    mapping(uint256 => ReserveAuction) private auctionIdToAuction;

    uint256 private _minPercentIncrementInBasisPoints;

    uint256 private _duration;

    // Cap the max duration so that overflows will not occur
    uint256 private constant MAX_MAX_DURATION = 1000 days;

    uint256 private constant EXTENSION_DURATION = 15 minutes;

    event ReserveAuctionConfigUpdated(
        uint256 minPercentIncrementInBasisPoints,
        uint256 maxBidIncrementRequirement,
        uint256 duration,
        uint256 extensionDuration,
        uint256 goLiveDate
    );

    event ReserveAuctionCreated(
        address indexed seller,
        address indexed nftContract,
        uint256[] tokenId,
        uint256 duration,
        uint256 extensionDuration,
        uint256 reservePrice,
        uint256 auctionId,
        bool canAuction
    );
    event ReserveAuctionUpdated(
        uint256 indexed auctionId,
        uint256 reservePrice
    );

    event ReserveAuctionCanceled(uint256 indexed auctionId);
    event ReserveAuctionBidPlaced(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 amount,
        uint256 endTime
    );
    event ReserveAuctionFinalized(
        uint256 indexed auctionId,
        address indexed seller,
        address indexed bidder,
        uint256 amount
    );
    event ReserveAuctionCanceledByAdmin(
        uint256 indexed auctionId,
        string reason
    );

    modifier onlyValidAuctionConfig(uint256 reservePrice) {
        require(
            reservePrice > 0,
            "NFTMarketReserveAuction: Reserve price must be at least 1 wei"
        );
        _;
    }

    /**
     * @notice Returns auction details for a given auctionId.
     */
    function getReserveAuction(uint256 auctionId)
        public
        view
        returns (ReserveAuction memory)
    {
        return auctionIdToAuction[auctionId];
    }

    /**
     * @notice Returns the current configuration for reserve auctions.
     */
    function getReserveAuctionConfig()
        public
        view
        returns (uint256 minPercentIncrementInBasisPoints, uint256 duration)
    {
        minPercentIncrementInBasisPoints = _minPercentIncrementInBasisPoints;
        duration = _duration;
    }

    function _initializeNFTMarketReserveAuction() internal {
        _duration = 21 days; // A sensible default value
    }

    function _updateReserveAuctionConfig(
        uint256 minPercentIncrementInBasisPoints,
        uint256 duration
    ) internal {
        require(
            minPercentIncrementInBasisPoints <= BASIS_POINTS,
            "NFTMarketReserveAuction: Min increment must be <= 100%"
        );
        // Cap the max duration so that overflows will not occur
        require(
            duration <= MAX_MAX_DURATION,
            "NFTMarketReserveAuction: Duration must be <= 1000 days"
        );
        require(
            duration >= EXTENSION_DURATION,
            "NFTMarketReserveAuction: Duration must be >= EXTENSION_DURATION"
        );
        _minPercentIncrementInBasisPoints = minPercentIncrementInBasisPoints;
        _duration = duration;

        // We continue to emit unused configuration variables to simplify the subgraph integration.
        emit ReserveAuctionConfigUpdated(
            minPercentIncrementInBasisPoints,
            0,
            duration,
            EXTENSION_DURATION,
            0
        );
    }

    /**
     * @notice Creates an auction for the given NFT.
     * The NFT is held in escrow until the auction is finalized or canceled.
     */
    function createReserveAuction(
        address nftContract,
        uint256[] memory tokenIds,
        uint256 reservePrice
    ) external onlyValidAuctionConfig(reservePrice) nonReentrant {
        // If an auction is already in progress then the NFT would be in escrow and the modifier would have failed
        require(tokenIds.length > 0, "Token id list can't be empty");
        uint256 auctionId = _getNextAndIncrementAuctionId();
        auctionIdToAuction[auctionId].nftContract = nftContract;
        auctionIdToAuction[auctionId].tokenId = tokenIds;
        auctionIdToAuction[auctionId].seller = address(msg.sender);
        auctionIdToAuction[auctionId].duration = _duration;
        auctionIdToAuction[auctionId].extensionDuration = EXTENSION_DURATION;
        auctionIdToAuction[auctionId].amount = reservePrice;
        if (_isWethioAdmin()) {
            auctionIdToAuction[auctionId].canAuction = true;
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            IERC721Upgradeable(nftContract).transferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );
        }

        emit ReserveAuctionCreated(
            msg.sender,
            nftContract,
            tokenIds,
            _duration,
            EXTENSION_DURATION,
            reservePrice,
            auctionId,
            auctionIdToAuction[auctionId].canAuction
        );
    }

    /**
     * @notice If an auction has been created but has not yet received bids, the configuration
     * such as the reservePrice may be changed by the seller.
     */
    function updateReserveAuction(uint256 auctionId, uint256 reservePrice)
        external
        onlyValidAuctionConfig(reservePrice)
    {
        ReserveAuction storage auction = auctionIdToAuction[auctionId];
        require(
            auction.seller == msg.sender,
            "NFTMarketReserveAuction: Not your auction"
        );
        require(
            auction.endTime == 0,
            "NFTMarketReserveAuction: Auction in progress"
        );

        auction.amount = reservePrice;

        emit ReserveAuctionUpdated(auctionId, reservePrice);
    }

    /**
     * @notice If an auction has been created but has not yet received bids, it may be canceled by the seller.
     * The NFT is returned to the seller from escrow.
     */
    function cancelReserveAuction(uint256 auctionId) external nonReentrant {
        ReserveAuction memory auction = auctionIdToAuction[auctionId];
        require(
            auction.seller == msg.sender,
            "NFTMarketReserveAuction: Not your auction"
        );
        require(
            auction.endTime == 0,
            "NFTMarketReserveAuction: Auction in progress"
        );

        delete auctionIdToAuction[auctionId];

        for (uint256 k = 0; k < auction.tokenId.length; k++) {
            IERC721Upgradeable(auction.nftContract).transferFrom(
                address(this),
                auction.seller,
                auction.tokenId[k]
            );
        }

        emit ReserveAuctionCanceled(auctionId);
    }

    /**
     * @notice A bidder may place a bid which is at least the value defined by `getMinBidAmount`.
     * If this is the first bid on the auction, the countdown will begin.
     * If there is already an outstanding bid, the previous bidder will be refunded at this time
     * and if the bid is placed in the final moment of the auction, the countdown may be extended.
     */
    function placeBid(uint256 auctionId) external payable nonReentrant {
        ReserveAuction storage auction = auctionIdToAuction[auctionId];
        require(
            auction.canAuction == true,
            "NFTMarketReserveAuction: Auction not found"
        );

        if (auction.endTime == 0) {
            // If this is the first bid, ensure it's >= the reserve price
            require(
                auction.amount <= msg.value,
                "NFTMarketReserveAuction: Bid must be at least the reserve price"
            );
        } else {
            // If this bid outbids another, confirm that the bid is at least x% greater than the last
            require(
                auction.endTime >= block.timestamp,
                "NFTMarketReserveAuction: Auction is over"
            );
            require(
                auction.bidder != msg.sender,
                "NFTMarketReserveAuction: You already have an outstanding bid"
            );
            uint256 minAmount = _getMinBidAmountForReserveAuction(
                auction.amount
            );
            require(
                msg.value >= minAmount,
                "NFTMarketReserveAuction: Bid amount too low"
            );
        }

        if (auction.endTime == 0) {
            auction.amount = msg.value;
            auction.bidder = msg.sender;
            // On the first bid, the endTime is now + duration
            auction.endTime = block.timestamp + auction.duration;
        } else {
            // Cache and update bidder state before a possible reentrancy (via the value transfer)
            uint256 originalAmount = auction.amount;
            address originalBidder = auction.bidder;
            auction.amount = msg.value;
            auction.bidder = msg.sender;

            // When a bid outbids another, check to see if a time extension should apply.
            if (auction.endTime - block.timestamp < auction.extensionDuration) {
                auction.endTime = block.timestamp + auction.extensionDuration;
            }

            // Refund the previous bidder
            _sendValueWithFallbackWithdrawWithLowGasLimit(
                originalBidder,
                originalAmount
            );
        }

        emit ReserveAuctionBidPlaced(
            auctionId,
            msg.sender,
            msg.value,
            auction.endTime
        );
    }

    /**
     * @notice Once the countdown has expired for an auction, anyone can settle the auction.
     * This will send the NFT to the highest bidder and distribute funds.
     */
    function finalizeReserveAuction(uint256 auctionId) external nonReentrant {
        ReserveAuction memory auction = auctionIdToAuction[auctionId];
        require(
            auction.endTime > 0,
            "NFTMarketReserveAuction: Auction was already settled"
        );
        require(
            auction.endTime < block.timestamp,
            "NFTMarketReserveAuction: Auction still in progress"
        );

        delete auctionIdToAuction[auctionId];

        for (uint256 j = 0; j < auction.tokenId.length; j++) {
            IERC721Upgradeable(auction.nftContract).transferFrom(
                address(this),
                auction.bidder,
                auction.tokenId[j]
            );
        }

        _sendValueWithFallbackWithdrawWithMediumGasLimit(
            auction.seller,
            auction.amount
        );

        emit ReserveAuctionFinalized(
            auctionId,
            auction.seller,
            auction.bidder,
            auction.amount
        );
    }

    /**
     * @notice Returns the minimum amount a bidder must spend to participate in an auction.
     */
    function getMinBidAmount(uint256 auctionId) public view returns (uint256) {
        ReserveAuction storage auction = auctionIdToAuction[auctionId];
        if (auction.endTime == 0) {
            return auction.amount;
        }
        return _getMinBidAmountForReserveAuction(auction.amount);
    }

    /**
     * @dev Determines the minimum bid amount when outbidding another user.
     */
    function _getMinBidAmountForReserveAuction(uint256 currentBidAmount)
        private
        view
        returns (uint256)
    {
        uint256 minIncrement = currentBidAmount.mul(
            _minPercentIncrementInBasisPoints
        ) / BASIS_POINTS;
        if (minIncrement == 0) {
            // The next bid must be at least 1 wei greater than the current.
            return currentBidAmount.add(1);
        }
        return minIncrement.add(currentBidAmount);
    }

    /**
     * @notice Allows Wethio to cancel an auction, refunding the bidder and returning the NFT to the seller.
     * This should only be used for extreme cases such as DMCA takedown requests. The reason should always be provided.
     */
    function adminCancelReserveAuction(uint256 auctionId, string memory reason)
        public
        onlyWethioAdmin
    {
        require(
            bytes(reason).length > 0,
            "NFTMarketReserveAuction: Include a reason for this cancellation"
        );
        ReserveAuction memory auction = auctionIdToAuction[auctionId];
        require(
            auction.amount > 0,
            "NFTMarketReserveAuction: Auction not found"
        );

        delete auctionIdToAuction[auctionId];

        for (uint256 k = 0; k < auction.tokenId.length; k++) {
            IERC721Upgradeable(auction.nftContract).transferFrom(
                address(this),
                auction.seller,
                auction.tokenId[k]
            );
        }
        if (auction.endTime > 0) {
            _sendValueWithFallbackWithdrawWithMediumGasLimit(
                auction.bidder,
                auction.amount
            );
        }

        emit ReserveAuctionCanceledByAdmin(auctionId, reason);
    }

    /**
     * @notice Allows Wethio to approve the auction for listing in market place;
     */
    function approveAuctionByAdmin(
        uint256 auctionId,
        bool status,
        string memory reason
    ) external onlyWethioAdmin {
        ReserveAuction memory auction = auctionIdToAuction[auctionId];
        require(
            auction.canAuction == false && auction.amount > 0,
            "Already approved or auction don't exist"
        );
        require(auction.endTime == 0, "Auction already started");

        if (status) {
            auctionIdToAuction[auctionId].canAuction = true;
        } else {
            adminCancelReserveAuction(auctionId, reason);
        }
    }

    uint256[1000] private ______gap;
}
