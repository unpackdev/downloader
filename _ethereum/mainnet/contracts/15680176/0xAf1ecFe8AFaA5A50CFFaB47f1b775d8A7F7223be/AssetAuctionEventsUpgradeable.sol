// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Initializable.sol";

/**
 * @title AssetAuctionEventsUpgradeable
 * @author NeatFi
 * @notice This contract holds the events for the Asset Auction module of NeatFi.
 */
contract AssetAuctionEventsUpgradeable is Initializable {
    /**
     * @dev Fired when a bid is recorded for an English Auction Order.
     * @param bidder - The address of the bidder.
     * @param orderHash - The hash of the Order.
     * @param bidValue - The value of the committment in native tokens.
     */
    event EnglishAuctionBid(
        address bidder,
        bytes32 orderHash,
        uint256 bidValue
    );

    /**
     * @dev Fired when a bid is recorded for a Dutch Auction Order.
     * @param bidder - The address of the bidder.
     * @param orderHash - The hash of the Order.
     * @param bidValue - The value of the committment in native tokens.
     */
    event DutchAuctionBid(address bidder, bytes32 orderHash, uint256 bidValue);

    /**
     * @dev Fired when the Order maker approves the last bidder's committment.
     * @param orderHash - The hash of the Order.
     * @param bidder - The address of the bidder.
     */
    event LastBidApproved(bytes32 orderHash, address bidder);

    /**
     * @dev Fired when an approved bidder claims an Auction Order (English or Dutch).
     * @param orderHash - The hash of the Order.
     * @param bidder - The address of the bidder.
     */
    event AuctionClaimed(bytes32 orderHash, address bidder);

    /** Initializers  */

    function __AssetAuctionEvents_init() internal initializer {
        __AssetAuctionEvents_init_unchained();
    }

    function __AssetAuctionEvents_init_unchained() internal initializer {}
}
