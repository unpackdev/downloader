// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./SeenTypes.sol";
import "./IMarketHandler.sol";

/**
 * @title IAuctionEnder
 *
 * @notice Handles the operation of Seen.Haus auctions.
 *
 * The ERC-165 identifier for this interface is: 0xb5db7fa6
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
interface IAuctionEnder is IMarketHandler {

    // Events
    event AuctionEnded(uint256 indexed consignmentId, SeenTypes.Outcome indexed outcome);
    event CanceledAuctionBidReturned(uint256 indexed consignmentId, address indexed buyer, uint256 indexed bid);
    event TokenHistoryTracker(address indexed tokenAddress, uint256 indexed tokenId, address indexed buyer, uint256 value, uint256 amount, uint256 consignmentId);

    /**
     * @notice Close out a successfully completed auction.
     *
     * Funds are disbursed as normal. See {MarketHandlerBase.disburseFunds}
     *
     * Reverts if:
     *  - Auction doesn't exist
     *  - Auction timer has not yet elapsed
     *  - Auction has not yet started
     *  - Auction has already been settled
     *  - Bids have been placed
     *
     * Emits a AuctionEnded event on success.
     *
     * @param _consignmentId - the id of the consignment being sold
     */
    function closeAuction(uint256 _consignmentId) external;

    /**
     * @notice Cancel an auction that hasn't ended yet.
     *
     * If there is a standing bid, it is returned to the bidder.
     * Consigned inventory will be transferred back to the seller.
     *
     * Reverts if:
     *  - Caller does not have ADMIN role
     *  - Auction doesn't exist
     *  - Auction has already been settled
     *
     * Emits a AuctionEnded event on success.
     *
     * @param _consignmentId - the id of the consignment being sold
     */
    function cancelAuction(uint256 _consignmentId) external;

}