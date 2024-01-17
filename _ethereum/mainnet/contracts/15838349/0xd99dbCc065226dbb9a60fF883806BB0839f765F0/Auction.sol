// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "./IERC721.sol";

/**
 * @author Sam King (samkingstudio.eth) for Fount Gallery
 * @title  Auction sale module
 * @notice TBD
 */
abstract contract Auction {
    /* ------------------------------------------------------------------------
                                   S T O R A G E
    ------------------------------------------------------------------------ */

    /// @notice Address of the NFT contract
    IERC721 public nft;

    /// @notice Tracks currently active auctions so withdrawals can be processed
    uint256 internal _activeAuctionCount;

    struct AuctionConfig {
        uint256 reservePrice;
        uint32 duration;
        uint32 timeBuffer;
        uint32 incrementPercentage;
    }

    /// @notice Configuration for all auctions
    AuctionConfig public auctionConfig;

    struct AuctionData {
        address listingOwner;
        uint32 startTime;
        uint32 firstBidTime;
        uint32 duration;
        uint96 highestBid;
        address highestBidder;
    }

    /// @notice Token id to auction config if one exists
    mapping(uint256 => AuctionData) public auctionForTokenId;

    /* ------------------------------------------------------------------------
                                    E R R O R S
    ------------------------------------------------------------------------ */

    error NonExistentToken();
    error AuctionNotStarted();
    error AuctionAlreadyExists();
    error AuctionAlreadyStarted();
    error AuctionReserveNotMet(uint256 reserve, uint256 sent);
    error AuctionMinimumBidNotMet(uint256 minBid, uint256 sent);
    error AuctionNotOver();
    error AuctionRefundFailed();
    error AuctionEnded();
    error AuctionAlreadySettled();

    /* ------------------------------------------------------------------------
                                    E V E N T S
    ------------------------------------------------------------------------ */

    event AuctionCreated(uint256 indexed id, AuctionData auction);
    event AuctionCancelled(uint256 indexed id, AuctionData auction);
    event AuctionBid(uint256 indexed id, AuctionData auction);
    event AuctionSettled(uint256 indexed id, AuctionData auction);

    /* ------------------------------------------------------------------------
                                      I N I T
    ------------------------------------------------------------------------ */

    constructor(address nft_, AuctionConfig memory config) {
        nft = IERC721(nft_);
        auctionConfig = config;
    }

    /* ------------------------------------------------------------------------
                             A U C T I O N   S E T U P
    ------------------------------------------------------------------------ */

    /**
     * @notice Creates an auction for a given token id
     * @dev Stores the token in this contract as escrow so it can be transferred to the winner,
     * and also prevents it being sold to someone else while an active auction is ongoing.
     *
     * Reverts if the auction already exists.
     *
     * @param id The token id to create the auction for
     * @param startTime The unix timestamp of when the auction should start allowing bids
     */
    function _createAuction(uint256 id, uint256 startTime) internal {
        AuctionData storage auction = auctionForTokenId[id];

        // Check there's no auction already
        if (auction.startTime > 0) revert AuctionAlreadyExists();

        // Check the token exists
        address nftOwner = nft.ownerOf(id);
        if (nftOwner == address(0)) revert NonExistentToken();

        // Create the auction in storage
        auction.startTime = uint32(startTime);
        auction.duration = uint32(auctionConfig.duration);
        auction.listingOwner = nftOwner;

        // Increment the number of active auctions
        unchecked {
            ++_activeAuctionCount;
        }

        // Transfer the token to this address as escrow
        nft.transferFrom(nftOwner, address(this), id);

        // Emit event
        emit AuctionCreated(id, auction);
    }

    /**
     * @notice Cancels a given auction. Can only be cancelled when there are no bids.
     * @dev Transfers the token back to the original minter so a subsequent auction can be created
     * @param id The token id used to create the auction
     */
    function _cancelAuction(uint256 id) internal {
        AuctionData storage auction = auctionForTokenId[id];

        // Check if the auction hasn't started
        if (auction.firstBidTime != 0) revert AuctionAlreadyStarted();

        // Transfer NFT back to the listing owner
        nft.transferFrom(address(this), auction.listingOwner, id);

        // Clean up the auction
        delete auctionForTokenId[id];
        unchecked {
            --_activeAuctionCount;
        }

        // Emit event
        emit AuctionCancelled(id, auction);
    }

    /* ------------------------------------------------------------------------
                            B I D   A N D   S E T T L E
    ------------------------------------------------------------------------ */

    /**
     * @notice Places a bid on a given auction
     * @dev Takes the amount of ETH sent as the bid.
     * - If the bid is the new highest bid, then the previous highest bidder is refunded.
     * - If a bid comes within the auction time buffer then the buffer is added to the
     *   time remaining on the auction e.g. extends by `AUCTION_TIME_BUFFER`.
     *
     * Reverts if:
     *   - The auction has not yet started
     *   - The auction has ended
     *   - The auction reserve bid has not been met if it's the first bid
     *   - The bid does not meet the minimum (increment percentage of current highest bid)
     *   - The ETH refund to the previous highest bidder fails
     *
     * @param id The token id of the auction to place a bid on
     */
    function _placeBid(uint256 id) internal {
        AuctionData storage auction = auctionForTokenId[id];

        // Check auction is ready to accept bids
        if (auction.startTime == 0 || auction.startTime > block.timestamp) {
            revert AuctionNotStarted();
        }

        // If first bid, start the auction
        if (auction.firstBidTime == 0) {
            // Check the first bid meets the reserve
            if (auctionConfig.reservePrice > msg.value) {
                revert AuctionReserveNotMet(auctionConfig.reservePrice, msg.value);
            }

            // Save the bid time
            auction.firstBidTime = uint32(block.timestamp);
        } else {
            // Check it hasn't ended
            if (block.timestamp > (auction.firstBidTime + auction.duration)) revert AuctionEnded();

            // Check the value sent meets the minimum price increase
            uint256 highestBid = auction.highestBid;
            uint256 minBid;
            unchecked {
                minBid = highestBid + ((highestBid * auctionConfig.incrementPercentage) / 100);
            }
            if (minBid > msg.value) revert AuctionMinimumBidNotMet(minBid, msg.value);

            // Refund the previous highest bid
            (bool refunded, ) = payable(auction.highestBidder).call{value: highestBid}("");
            if (!refunded) revert AuctionRefundFailed();
        }

        // Save the highest bid and bidder
        auction.highestBid = uint96(msg.value);
        auction.highestBidder = msg.sender;

        // Calculate the time remaining
        uint256 timeRemaining;
        unchecked {
            timeRemaining = auction.firstBidTime + auction.duration - block.timestamp;
        }

        // If bid is placed within the time buffer of the auction ending, increase the duration
        if (timeRemaining < auctionConfig.timeBuffer) {
            unchecked {
                auction.duration += uint32(auctionConfig.timeBuffer - timeRemaining);
            }
        }

        // Emit event
        emit AuctionBid(id, auction);
    }

    /**
     * @notice Allows the winner to settle the auction, taking ownership of their new NFT
     * @dev Transfers the NFT to the highest bidder (winner) only once the auction is over.
     * Can be called by anyone so the artist, or the team can pay the gas if needed.
     *
     * Reverts if:
     *   - The auction hasn't started yet
     *   - The auction is not over
     *
     * @param id The token id of the auction to settle
     */
    function _settleAuction(uint256 id) internal {
        AuctionData storage auction = auctionForTokenId[id];

        // Check auction has started
        if (auction.firstBidTime == 0) revert AuctionNotStarted();

        // Check auction has ended
        if (auction.firstBidTime + auction.duration > block.timestamp) revert AuctionNotOver();

        // Check if this contract still has the NFT indicating it has not been settled
        if (nft.ownerOf(id) != address(this)) revert AuctionAlreadySettled();

        // Transfer NFT to highest bidder
        nft.transferFrom(address(this), auction.highestBidder, id);

        // Decrease the active auction count
        unchecked {
            --_activeAuctionCount;
        }

        // Emit event
        emit AuctionSettled(id, auction);
    }

    /* ------------------------------------------------------------------------
                                   G E T T E R S
    ------------------------------------------------------------------------ */

    function auctionHasStarted(uint256 id) external view returns (bool) {
        return auctionForTokenId[id].firstBidTime > 0;
    }

    function auctionStartTime(uint256 id) external view returns (uint256) {
        return auctionForTokenId[id].startTime;
    }

    function auctionHasEnded(uint256 id) external view returns (bool) {
        AuctionData memory auction = auctionForTokenId[id];
        bool hasStarted = auctionForTokenId[id].firstBidTime > 0;
        return hasStarted && block.timestamp > auction.firstBidTime + auction.duration;
    }

    function auctionEndTime(uint256 id) external view returns (uint256) {
        AuctionData memory auction = auctionForTokenId[id];
        bool hasStarted = auctionForTokenId[id].firstBidTime > 0;
        return hasStarted ? auction.startTime + auction.duration : 0;
    }

    function auctionDuration(uint256 id) external view returns (uint256) {
        AuctionData memory auction = auctionForTokenId[id];
        return auction.duration > 0 ? auction.duration : auctionConfig.duration;
    }

    function auctionHighestBidder(uint256 id) external view returns (address) {
        return auctionForTokenId[id].highestBidder;
    }

    function auctionHighestBid(uint256 id) external view returns (uint256) {
        return auctionForTokenId[id].highestBid;
    }

    function auctionListingOwner(uint256 id) external view returns (address) {
        return auctionForTokenId[id].listingOwner;
    }

    function totalActiveAuctions() external view returns (uint256) {
        return _activeAuctionCount;
    }
}
