// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./INeatFiProtocolStorage.sol";
import "./IAssetTransfer.sol";
import "./AssetStructsUpgradeable.sol";
import "./AssetEnumsUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./RoleConstantsUpgradeable.sol";
import "./AssetSwapStorageUpgradeable.sol";
import "./AssetSwapEventsUpgradeable.sol";

/**
 * @title AssetSwapOperationsUpgradeable
 * @author NeatFi
 * @notice This contract holds the operations for the Asset Swap
 *         module of Neatfi.
 */
contract AssetSwapOperationsUpgradeable is
    AssetEnumsUpgradeable,
    AssetStructsUpgradeable,
    RoleConstantsUpgradeable,
    AccessControlUpgradeable,
    AssetSwapEventsUpgradeable,
    AssetSwapStorageUpgradeable
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
     *      NeatFi protocol's current implementation.
     */
    function _updateAssetTransferAddress(address newAssetTransfer) internal {
        assetTransfer = newAssetTransfer;
    }

    /**
     * @dev An internal function to create a Bid type Order for a Swap Order.
     * @param bidder - The address of the bidder.
     * @param tokens - The array of Token assets to include in the Bid.
     * @param listingTime - The timestamp of the Bid creation.
     * @param orderHash - The hash of the Swap Order.
     * @param actorKey - The actor key of the Actor contract.
     * @return bidHash - The hash of the Bid type Order.
     */
    function _makeBid(
        address bidder,
        Token[] calldata tokens,
        uint256 listingTime,
        bytes32 orderHash,
        bytes32 actorKey
    ) internal returns (bytes32 bidHash) {
        require(
            INeatFiProtocolStorage(neatFiProtocolStorage).isValidOrder(
                orderHash
            ),
            "AssetSwapOperationsUpgradeable::_makeBid: invalid order."
        );

        Order memory order = INeatFiProtocolStorage(neatFiProtocolStorage)
            .getOrder(orderHash);

        require(
            order.orderType == AssetOrderType.SWAP,
            "AssetSwapOperationsUpgradeable::_makeBid: wrong order type."
        );

        require(
            bidder != order.maker,
            "AssetSwapOperationsUpgradeable::_makeBid: self-bidding is not available."
        );

        bidHash = INeatFiProtocolStorage(neatFiProtocolStorage).makeOrder(
            tokens,
            AssetOrderType.BID,
            bidder,
            listingTime,
            order.expirationTime,
            0,
            0,
            actorKey
        );

        bidsByOrder[orderHash].push(bidHash);

        emit BidForOrder(orderHash, bidHash);

        return bidHash;
    }

    /**
     * @dev An internal function for the Order maker to approve and resolve a Swap Order.
     * @param maker - The address of the Order maker.
     * @param orderHash - The hash of the Order.
     * @param bidHash - The hash of the Bid type Order.
     * @param orderData - Optional additional data to include with the transaction.
     * @param bidData - Optional additional data to include with the transaction.
     */
    function _approveAndResolveSwap(
        address maker,
        bytes32 orderHash,
        bytes32 bidHash,
        bytes calldata orderData,
        bytes calldata bidData
    ) internal {
        require(
            INeatFiProtocolStorage(neatFiProtocolStorage).isValidOrder(
                orderHash
            ),
            "AssetSwapOperationsUpgradeable::_approveAndResolveSwap: invalid order."
        );

        require(
            INeatFiProtocolStorage(neatFiProtocolStorage).isValidOwner(
                orderHash,
                maker
            )
        );

        require(
            INeatFiProtocolStorage(neatFiProtocolStorage).isValidOrder(bidHash),
            "AssetSwapOperationsUpgradeable::_approveAndResolveSwap: invalid order."
        );

        Order memory order = INeatFiProtocolStorage(neatFiProtocolStorage)
            .getOrder(orderHash);
        Order memory bid = INeatFiProtocolStorage(neatFiProtocolStorage)
            .getOrder(bidHash);

        swapEscrowParties[orderHash] = bidHash;

        INeatFiProtocolStorage(neatFiProtocolStorage).changeOrderStatus(
            orderHash,
            AssetOrderStatus.CLOSED
        );
        INeatFiProtocolStorage(neatFiProtocolStorage).changeOrderStatus(
            bidHash,
            AssetOrderStatus.CLOSED
        );

        IAssetTransfer(assetTransfer).transferResolver(
            order,
            maker,
            bid.maker,
            orderData
        );
        IAssetTransfer(assetTransfer).transferResolver(
            bid,
            bid.maker,
            maker,
            bidData
        );
    }

    /** Initializers */

    function __AssetSwapOperations_init(
        address newAssetTransfer,
        address newNeatFiProtocolStorage
    ) internal initializer {
        __AssetStructs_init();
        __AssetEnums_init();
        __AssetSwapStorage_init();
        __AssetSwapEvents_init();
        __RoleConstants_init();
        __AccessControl_init();

        _updateAssetTransferAddress(newAssetTransfer);
        _updateNeatFiProtocolStorageAddress(newNeatFiProtocolStorage);
    }
}
