// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * @title IAssetAuction
 * @author NeatFi
 * @notice Interface to the {AssetAuction} contract of NeatFi Auction module.
 */
interface IAssetAuction {
    /**
     * @notice Decreases the price of a Ducth Auction.
     * @dev Called only from the NeatFi contract.
     * @param maker - The address of the Order maker.
     * @param orderHash - The hash of the Order.
     * @param newPrice - The new price for the Order.
     */
    function decreaseDucthAuctionPrice(
        address maker,
        bytes32 orderHash,
        uint256 newPrice
    ) external;

    /**
     * @notice Increases the price of a English Auction.
     * @dev Called only from the NeatFi contract.
     * @param maker - The address of the Order maker.
     * @param orderHash - The hash of the Order.
     * @param newPrice - The new price for the Order.
     */
    function increaseEnglishAuctionPrice(
        address maker,
        bytes32 orderHash,
        uint256 newPrice
    ) external;

    /**
     * @notice Places a bid in native tokens (i.e. Eth for Ethereum) for an English Auction.
     * @dev Called only from the NeatFi contract.
     * @param bidder - The address of the bidder.
     * @param orderHash - The hash of the Order.
     * @param bidValue - The bidding value in native tokens.
     */
    function bidForEnglishAuction(
        address bidder,
        bytes32 orderHash,
        uint256 bidValue
    ) external;

    /**
     * @notice Places a bid in native tokens (i.e. Eth for Ethereum) for a Dutch Auction.
     * @dev Called only from the NeatFi contract.
     * @param bidder - The address of the bidder.
     * @param orderHash - The hash of the Order.
     * @param bidValue - The bidding value in native tokens.
     */
    function bidForDutchAuction(
        address bidder,
        bytes32 orderHash,
        uint256 bidValue
    ) external;

    /**
     * @notice Approves the last bid for an English or Ducth Auction Order.
     * @dev Called only from the NeaFi contract.
     * @param maker - The address of the Order maker.
     * @param orderHash - The hash of the Order.
     */
    function approveLastBid(address maker, bytes32 orderHash) external;

    /**
     * @notice Claims an English or a Ducth Auction Order.
     * @dev Called only from the NeatFi contract.
     * @param bidder - The address of the bidder.
     * @param orderHash - The hash of the Order.
     * @param data - Optional additional data to include with the transaction.
     */
    function claimAuction(
        address bidder,
        bytes32 orderHash,
        bytes calldata data
    ) external;

    /**
     * @notice Gets the last bidding address for an Order.
     * @param orderHash - The hash of the Order.
     * @return lastBidder - The address of the last bidder.
     */
    function getLastBidderAddress(bytes32 orderHash)
        external
        view
        returns (address lastBidder);
}
