// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./INeatFiProtocolStorage.sol";
import "./IAssetTransfer.sol";
import "./AssetStructsUpgradeable.sol";
import "./AssetEnumsUpgradeable.sol";
import "./AssetAuctionStorageUpgradeable.sol";
import "./AssetAuctionEventsUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./RoleConstantsUpgradeable.sol";

/**
 * @title AssetAuctionOperationsUpgradeable
 * @author NeatFi
 * @notice This contract holds the operations for the Asset Auction
 *         module of Neatfi.
 */
contract AssetAuctionOperationsUpgradeable is
    AssetEnumsUpgradeable,
    AssetStructsUpgradeable,
    AssetAuctionStorageUpgradeable,
    AssetAuctionEventsUpgradeable,
    RoleConstantsUpgradeable,
    AccessControlUpgradeable
{
    address internal neatFiProtocolStorage;
    address internal assetTransfer;

    /**
     * @dev An internal function to update the address of the
     *      NeatFi protocol's current implementation.
     */
    function _updateNeatFiProtocolStorageAddress(
        address newNeatFiProtocolStorage
    ) internal {
        neatFiProtocolStorage = newNeatFiProtocolStorage;
    }

    /**
     * @dev An internal function to update the address of the
     *      Asset Transfer contract's current implementation.
     */
    function _updateAssetTransferAddress(address newAssetTransfer) internal {
        assetTransfer = newAssetTransfer;
    }

    /**
     * @dev Internal function to change the price of a Dutch Auction Order.
     *      Only available for the Order maker.
     * @param maker - The address of the Order maker.
     * @param orderHash - The hash of the Order.
     * @param newPrice - The new price of the Order.
     */
    function _decreaseDucthAuctionPrice(
        address maker,
        bytes32 orderHash,
        uint256 newPrice
    ) internal {
        require(
            INeatFiProtocolStorage(neatFiProtocolStorage).isValidOwner(
                orderHash,
                maker
            ),
            "AssetAuctionOperationsUpgradeable::_decreaseDucthAuctionPrice: ownership check failed."
        );

        require(
            INeatFiProtocolStorage(neatFiProtocolStorage).isValidOrder(
                orderHash
            ),
            "AssetAuctionOperationsUpgradeable::_decreaseDucthAuctionPrice: invalid order."
        );

        Order memory order = INeatFiProtocolStorage(neatFiProtocolStorage)
            .getOrder(orderHash);

        require(
            order.orderType == AssetOrderType.DUTCH_AUCTION,
            "AssetAuctionOperationsUpgradeable::_decreaseDucthAuctionPrice: wrong order type."
        );

        require(
            newPrice < order.endPrice,
            "AssetAuctionOperationsUpgradeable::_decreaseDucthAuctionPrice: price can only be decreased."
        );

        INeatFiProtocolStorage(neatFiProtocolStorage).changeOrderEndPrice(
            orderHash,
            newPrice
        );
    }

    /**
     * @dev Internal function to change the price of an English Auction Order.
     *      Only available for the Order maker.
     * @param maker - The address of the Order maker.
     * @param orderHash - The hash of the Order.
     * @param newPrice - The new price of the Order.
     */
    function _increaseEnglishAuctionPrice(
        address maker,
        bytes32 orderHash,
        uint256 newPrice
    ) internal {
        require(
            INeatFiProtocolStorage(neatFiProtocolStorage).isValidOwner(
                orderHash,
                maker
            ),
            "AssetAuctionOperationsUpgradeable::_increaseEnglishAuctionPrice: ownership check failed."
        );

        require(
            INeatFiProtocolStorage(neatFiProtocolStorage).isValidOrder(
                orderHash
            ),
            "AssetAuctionOperationsUpgradeable::_increaseEnglishAuctionPrice: invalid order."
        );

        Order memory order = INeatFiProtocolStorage(neatFiProtocolStorage)
            .getOrder(orderHash);

        require(
            order.orderType == AssetOrderType.ENGLISH_AUCTION,
            "AssetAuctionOperationsUpgradeable::_increaseEnglishAuctionPrice: wrong order type."
        );

        require(
            newPrice > order.endPrice,
            "AssetAuctionOperationsUpgradeable::_increaseEnglishAuctionPrice: price can only be increased."
        );

        INeatFiProtocolStorage(neatFiProtocolStorage).changeOrderEndPrice(
            orderHash,
            newPrice
        );
    }

    /**
     * @dev An internal function to record a bid committment in native tokens
     *      for an English Auction Order.
     * @param bidder - The address of the bidder.
     * @param orderHash - The hash of the Order.
     * @param bidValue - The value of the bid committment.
     */
    function _bidForEnglishAuction(
        address bidder,
        bytes32 orderHash,
        uint256 bidValue
    ) internal {
        require(
            INeatFiProtocolStorage(neatFiProtocolStorage).isValidOrder(
                orderHash
            ),
            "AssetAuctionOperationsUpgradeable::_bidForEnglishAuction: invalid order."
        );

        Order memory order = INeatFiProtocolStorage(neatFiProtocolStorage)
            .getOrder(orderHash);

        require(
            order.orderType == AssetOrderType.ENGLISH_AUCTION,
            "AssetAuctionOperationsUpgradeable::_bidForEnglishAuction: wWrong order type."
        );

        require(
            bidValue > order.endPrice,
            "AssetAuctionOperations::_bidForEnglishAuction: invalid bid value."
        );

        INeatFiProtocolStorage(neatFiProtocolStorage).changeOrderEndPrice(
            orderHash,
            bidValue
        );

        lastBidderForOrder[orderHash] = bidder;

        if (block.timestamp < order.expirationTime - 300) {
            INeatFiProtocolStorage(neatFiProtocolStorage)
                .changeOrderExpirationTime(
                    orderHash,
                    order.expirationTime + 300
                );
        }

        emit EnglishAuctionBid(bidder, orderHash, bidValue);
    }

    /**
     * @dev An internal function to record a bid committment in native tokens
     *      for a Dutch Auction Order.
     * @param bidder - The address of the bidder.
     * @param orderHash - The hash of the Order.
     * @param bidValue - The value of the bid committment.
     */
    function _bidForDutchAuction(
        address bidder,
        bytes32 orderHash,
        uint256 bidValue
    ) internal {
        require(
            INeatFiProtocolStorage(neatFiProtocolStorage).isValidOrder(
                orderHash
            ),
            "AssetAuctionOperationsUpgradeable::_bidForDutchAuction: invalid order."
        );

        Order memory order = INeatFiProtocolStorage(neatFiProtocolStorage)
            .getOrder(orderHash);

        require(
            order.orderType == AssetOrderType.DUTCH_AUCTION,
            "AssetAuctionOperationsUpgradeable::_bidForDutchAuction: wWrong order type."
        );

        require(
            bidValue < order.endPrice,
            "AssetAuctionOperations::_bidForDutchAuction: invalid bid value."
        );

        INeatFiProtocolStorage(neatFiProtocolStorage).changeOrderEndPrice(
            orderHash,
            bidValue
        );

        lastBidderForOrder[orderHash] = bidder;

        if (block.timestamp < order.expirationTime - 300) {
            INeatFiProtocolStorage(neatFiProtocolStorage)
                .changeOrderExpirationTime(
                    orderHash,
                    order.expirationTime + 300
                );
        }

        emit DutchAuctionBid(bidder, orderHash, bidValue);
    }

    /**
     * @dev An internal function for the maker to approve the
     *      last bidder to claim the Order.
     * @param orderHash - The hash of the Order.
     * @param maker - The address of the Order maker.
     */
    function _approveLastBid(address maker, bytes32 orderHash) internal {
        require(
            INeatFiProtocolStorage(neatFiProtocolStorage).isValidOrder(
                orderHash
            ),
            "AssetAuctionOperations::_approveLastBid: invalid order."
        );

        require(
            INeatFiProtocolStorage(neatFiProtocolStorage).isValidOwner(
                orderHash,
                maker
            ),
            "AssetAuctionOperations::_approveLastBid: ownership check failed."
        );

        Order memory order = INeatFiProtocolStorage(neatFiProtocolStorage)
            .getOrder(orderHash);

        require(
            order.orderType == AssetOrderType.ENGLISH_AUCTION ||
                order.orderType == AssetOrderType.DUTCH_AUCTION,
            "AssetAuctionOperations::_approveLastBid: wrong order type."
        );

        address bidder = lastBidderForOrder[orderHash];

        INeatFiProtocolStorage(neatFiProtocolStorage).changeOrderStatus(
            orderHash,
            AssetOrderStatus.PROCESSING
        );

        emit LastBidApproved(orderHash, bidder);
    }

    /**
     * @dev An internal function for the approved bidder to claim
     *      an Auction Order (English or Dutch).
     * @param orderHash - The hash of the Order.
     * @param bidder - The address of the approved bidder.
     */
    function _claimAuction(
        address bidder,
        bytes32 orderHash,
        bytes calldata data
    ) internal {
        Order memory order = INeatFiProtocolStorage(neatFiProtocolStorage)
            .getOrder(orderHash);

        require(
            lastBidderForOrder[orderHash] == bidder,
            "AssetAuctionOperations::_claimAuction: claimant is not the last approved bidder of this auction."
        );

        require(
            order.status == AssetOrderStatus.PROCESSING,
            "AssetAuctionOperations::_claimAuction: order is not in processing."
        );

        INeatFiProtocolStorage(neatFiProtocolStorage).changeOrderStatus(
            orderHash,
            AssetOrderStatus.CLOSED
        );

        IAssetTransfer(assetTransfer).transferResolver(
            order,
            order.maker,
            bidder,
            data
        );

        emit AuctionClaimed(orderHash, bidder);
    }

    /** Initializers */

    function __AssetAuctionOperations_init(
        address newAssetTransfer,
        address newNeatFiProtocolStorage
    ) internal initializer {
        __AssetStructs_init();
        __AssetEnums_init();
        __AssetAuctionStorage_init();
        __AssetAuctionEvents_init();
        __RoleConstants_init();
        __AccessControl_init();

        _updateNeatFiProtocolStorageAddress(newNeatFiProtocolStorage);
        _updateAssetTransferAddress(newAssetTransfer);
    }
}
