// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./AssetStructsUpgradeable.sol";
import "./AssetEnumsUpgradeable.sol";

/**
 * @title INeatFi
 * @author NeatFi
 * @notice Interface to the main {NeatFi} contract of NeatFi.
 */
interface INeatFi {
    /**
     * @notice Requests an actor key. Must be the first function to call from an
     *         Actor implementation contract. Upon approval and actor key generation,
     *         the Actor is able to interact with NeatFi modules.
     * @param actorAddress - The address of the Actor contract.
     */
    function requestActorKey(address actorAddress) external;

    /**
     * @notice Changes the fee distribution address for an Actor.
     * @param actorAddress - The address of the Actor contract.
     * @param newFeeDistributionAddress - The new receiver address
     *                                    of protocol fees.
     */
    function changeFeeDistributionAddress(
        address actorAddress,
        address payable newFeeDistributionAddress
    ) external;

    /**
     * @notice Retrieves the fee distribution address of an Actor.
     * @param actorAddress - The address of the Actor.
     * @return feeDistributionAddress - The address of fee distribution.
     */
    function getFeeDistributionAddress(address actorAddress)
        external
        view
        returns (address payable feeDistributionAddress);

    /**
     * @dev Retrieves the protocol fee numerator for Swap Order creation.
     * @return sellProtocolFee - The protocol fee numerator for
     *                           a Swap Order creation.
     */
    function getSwapProtocolFee()
        external
        view
        returns (uint256 sellProtocolFee);

    /**
     * @notice Creates an Order.
     * @dev Called from any NeatFi implementation contracts.
     * @param tokens - The array of Token assets to include in the Order.
     * @param orderType - The enum ype of an Order.
     *                    0 - SELL,
     *                    1 - ENGLISH_AUCTION,
     *                    2 - DUTCH_AUCTION,
     *                    3 - SWAP
     *                    4 - BID
     * @param maker - The address of the Order maker. This is NOT the actor contract.
     * @param listingTime - The timestamp of the Order creation.
     * @param expirationTime - The timestamp of the Order expiration.
     * @param startPrice - The starting price of the Order.
     * @param actorKey - The actor key of the Actor contract through which the Order
     *                   is being created.
     * @return orderHash - The hash of the created Order.
     */
    function makeOrder(
        AssetStructsUpgradeable.Token[] calldata tokens,
        AssetEnumsUpgradeable.AssetOrderType orderType,
        address payable maker,
        uint256 listingTime,
        uint256 expirationTime,
        uint256 startPrice,
        bytes32 actorKey
    ) external payable returns (bytes32 orderHash);

    /**
     * @notice Creates a Bid type Order.
     * @dev Called from any NeatFi implementation contracts.
     * @param tokens - The array of Token assets to include in the Order.
     * @param bidder - The address of the bidder (maker of the Bid type Order).
     *                 This is NOT the actor contract.
     * @param listingTime - The timestamp of the Order creation.
     * @param actorKey - The actor key of the Actor contract through which the Order
     *                   is being created.
     * @param orderHash - The hash of the Order for which this Bid is created.
     * @return bidHash - The hash of the created Order.
     */
    function makeBid(
        AssetStructsUpgradeable.Token[] calldata tokens,
        address bidder,
        uint256 listingTime,
        bytes32 orderHash,
        bytes32 actorKey
    ) external returns (bytes32 bidHash);

    /**
     * @notice Maker cancels the Order.
     * @dev Called from any NeatFi implementation contracts.
     * @param maker - The address of the Order maker.
     * @param orderHash - The hash of the Order.
     */
    function cancelOrder(address maker, bytes32 orderHash) external;

    /**
     * @notice Maker approves and resolves a Swap Order.
     * @dev Called from any NeatFi implementation contracts.
     * @param maker - The address of the Order maker.
     * @param orderHash - The hash of the Order.
     * @param bidHash - The hash of the Bid type Order.
     * @param orderData - Optional additional data to include with the transaction.
     * @param bidData - Optional additional data to include with the transaction.
     */
    function approveAndResolveSwap(
        address maker,
        bytes32 orderHash,
        bytes32 bidHash,
        bytes calldata orderData,
        bytes calldata bidData
    ) external;

    /**
     * @notice Buyer immediately buys a Sell Order.
     * @dev Called from any NeatFi implementation contracts.
     * @param buyer - The address of the Order maker.
     * @param orderHash - The hash of the Order.
     * @param data - Optional additional data to include with the transaction.
     */
    function buyItNow(
        address buyer,
        bytes32 orderHash,
        bytes calldata data
    ) external payable;

    /**
     * @notice Maker decreases the price of a Dutch Auction.
     * @dev Called from any NeatFi implementation contracts.
     * @param maker - The address of the Order maker.
     * @param orderHash - The hash of the Order.
     * @param newPrice - The new end price of the Order.
     */
    function decreaseDucthAuctionPrice(
        address maker,
        bytes32 orderHash,
        uint256 newPrice
    ) external;

    /**
     * @notice Maker increases the price of an English Auction.
     * @dev Called from any NeatFi implementation contracts.
     * @param maker - The address of the Order maker.
     * @param orderHash - The hash of the Order.
     * @param newPrice - The new end price of the Order.
     */
    function increaseEnglishAuctionPrice(
        address maker,
        bytes32 orderHash,
        uint256 newPrice
    ) external;

    /**
     * @notice The bidder commits native tokens (i.e. Eth for Ethereum) for an
     *         English Auction. The native tokens are not transferred from the
     *         bidder yet.
     * @dev Called from any NeatFi implementation contracts.
     * @param bidder - The address of the bidder.
     * @param orderHash - The hash of the Order.
     * @param bidValue - The committment of the bidder in native tokens.
     */
    function bidForEnglishAuction(
        address bidder,
        bytes32 orderHash,
        uint256 bidValue
    ) external;

    /**
     * @notice The bidder commits native tokens (i.e. Eth for Ethereum) for a
     *         Dutch Auction. The native tokens are not transferred from the
     *         bidder yet.
     * @dev Called from any NeatFi implementation contracts.
     * @param bidder - The address of the bidder.
     * @param orderHash - The hash of the Order.
     * @param bidValue - The committment of the bidder in native tokens.
     */
    function bidForDutchAuction(
        address bidder,
        bytes32 orderHash,
        uint256 bidValue
    ) external;

    /**
     * @notice The maker approves the last bid in native tokens.
     * @dev Called from any NeatFi implementation contracts.
     * @param maker - The address of the maker.
     * @param orderHash - The hash of the Order.
     */
    function approveLastBid(address maker, bytes32 orderHash) external;

    /**
     * @notice The approved bidder claims the English Auction Order.
     * @dev Called from any NeatFi implementation contracts.
     * @param bidder - The address of the bidder.
     * @param orderHash - The hash of the Order.
     * @param data - Optional additional data to include with the transaction.
     */
    function claimEnglishAuction(
        address bidder,
        bytes32 orderHash,
        bytes calldata data
    ) external payable;

    /**
     * @notice The approved bidder claims the Dutch Auction Order.
     * @dev Called from any NeatFi implementation contracts.
     * @param bidder - The address of the bidder.
     * @param orderHash - The hash of the Order.
     * @param data - Optional additional data to include with the transaction.
     */
    function claimDutchAuction(
        address bidder,
        bytes32 orderHash,
        bytes calldata data
    ) external payable;
}
