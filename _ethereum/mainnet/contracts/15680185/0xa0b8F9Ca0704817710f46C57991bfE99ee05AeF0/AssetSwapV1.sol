// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./AssetSwapOperationsUpgradeable.sol";
import "./UUPSUpgradeable.sol";

/**
 * @title AssetSwapV1
 * @author NeatFi
 * @notice This contract implements the external facing functionality
 *         for the Asset Swap module of NeatFi.
 */
contract AssetSwapV1 is AssetSwapOperationsUpgradeable, UUPSUpgradeable {
    string internal name;
    string internal currentVersion;

    /**
     * @dev Sets the version for the current implementation of this contract.
     */
    function _setVersion(string memory newVersion) internal {
        currentVersion = newVersion;
    }

    /**
     * @dev Updates the NeatFi Protocol storage address. Can be executed by a
     *      Protocol Admin only.
     */
    function updateNeatFiProtocolStorageAddress(
        address newNeatFiProtocolStorage
    ) external onlyRole(PROTOCOL_ADMIN) {
        _updateNeatFiProtocolStorageAddress(newNeatFiProtocolStorage);
    }

    /**
     * @dev Updates the Asset Transfer contract address. Can be executed by a
     *      Protocol Admin only.
     */
    function updateAssetTransferAddress(address newAssetTransfer)
        external
        onlyRole(PROTOCOL_ADMIN)
    {
        _updateAssetTransferAddress(newAssetTransfer);
    }

    /**
     * @dev An external function to create a Bid type Order for a Swap Order.
     *      Can be called from the NeatFi contract only.
     * @param bidder - The address of the bidder.
     * @param tokens - The array of Token assets to include in the Bid.
     * @param listingTime - The timestamp of the Bid creation.
     * @param orderHash - The hash of the Swap Order.
     * @param actorKey - The actor key of the Actor contract.
     * @return bidHash - The hash of the Bid type Order.
     */
    function makeBid(
        address bidder,
        Token[] calldata tokens,
        uint256 listingTime,
        bytes32 orderHash,
        bytes32 actorKey
    ) external onlyRole(AUTHORIZED_OPERATOR) returns (bytes32 bidHash) {
        return _makeBid(bidder, tokens, listingTime, orderHash, actorKey);
    }

    /**
     * @dev An external function for the Order maker to approve and resolve a Swap Order.
     *      Can be called from the NeatFi contract only.
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
    ) external onlyRole(AUTHORIZED_OPERATOR) {
        _approveAndResolveSwap(maker, orderHash, bidHash, orderData, bidData);
    }

    /** Initializers */

    function _authorizeUpgrade(address newImplementation) internal override {}

    function initialize(
        address neatFiProtocolStorageAddress,
        address assetTransferAddress
    ) public initializer onlyProxy {
        __UUPSUpgradeable_init();
        __AssetSwapOperations_init(
            assetTransferAddress,
            neatFiProtocolStorageAddress
        );

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        name = "NeatFi Asset Swap Module";
        _setVersion("1.0.0");
    }
}
