// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./INeatFiProtocolStorage.sol";
import "./IAssetTransfer.sol";
import "./AssetStructsUpgradeable.sol";
import "./AssetEnumsUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./RoleConstantsUpgradeable.sol";

/**
 * @title AssetSellOperationsUpgradeable
 * @author NeatFi
 * @notice This contract holds the operations for the Asset Sell
 *         module of Neatfi.
 */
contract AssetSellOperationsUpgradeable is
    AssetEnumsUpgradeable,
    AssetStructsUpgradeable,
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
     * @dev An internal function to instantly buy an Order. Handles the
     *      transfer of the Token assets in the Order to the buyer.
     * @param orderHash - The hash of the Order.
     * @param purchaseValue - The end price of the Order, in native tokens.
     * @param buyer - The address of the buyer.
     * @param data - Optional additional data to include with the transaction.
     */
    function _buyItNow(
        bytes32 orderHash,
        uint256 purchaseValue,
        address buyer,
        bytes calldata data
    ) internal {
        require(
            INeatFiProtocolStorage(neatFiProtocolStorage).isValidOrder(
                orderHash
            ),
            "AssetSellOperationsUpgradeable::_buyItNow: invalid order."
        );

        Order memory order = INeatFiProtocolStorage(neatFiProtocolStorage)
            .getOrder(orderHash);

        require(
            order.maker != buyer,
            "AssetSellOperationsUpgradeable::_buyItNow: buyer can not be the order maker"
        );

        require(
            order.orderType == AssetOrderType.SELL,
            "AssetSellOperationsUpgradeable::_buyItNow: wrong order type."
        );

        require(
            order.endPrice == purchaseValue,
            "AssetSellOperationsUpgradeable::_buyItNow: wrong purchase value."
        );

        INeatFiProtocolStorage(neatFiProtocolStorage).changeOrderStatus(
            orderHash,
            AssetOrderStatus.CLOSED
        );

        IAssetTransfer(assetTransfer).transferResolver(
            order,
            order.maker,
            buyer,
            data
        );
    }

    /** Initializers */

    function __AssetSellOperations_init(
        address newAssetTransfer,
        address newNeatFiProtocolStorage
    ) internal initializer {
        __AssetStructs_init();
        __AssetEnums_init();
        __RoleConstants_init();
        __AccessControl_init();

        _updateAssetTransferAddress(newAssetTransfer);
        _updateNeatFiProtocolStorageAddress(newNeatFiProtocolStorage);
    }
}
