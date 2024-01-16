// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./AssetAuctionOperationsUpgradeable.sol";
import "./UUPSUpgradeable.sol";

/**
 * @title AssetAuctionV1
 * @author NeatFi
 * @notice This contract implements the external facing functionality
 *         for the Asset Auction module of NeatFi.
 */
contract AssetAuctionV1 is AssetAuctionOperationsUpgradeable, UUPSUpgradeable {
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
     * @dev An external function to change the price of a Dutch Auction Order.
     *      Only available for the Order maker. Can be called from the NeatFi
     *      contract only.
     * @param maker - The address of the Order maker.
     * @param orderHash - The hash of the Order.
     * @param newPrice - The new price of the Order.
     */
    function decreaseDucthAuctionPrice(
        address maker,
        bytes32 orderHash,
        uint256 newPrice
    ) external onlyRole(AUTHORIZED_OPERATOR) {
        _decreaseDucthAuctionPrice(maker, orderHash, newPrice);
    }

    /**
     * @dev An external function to change the price of an English Auction Order.
     *      Only available for the Order maker. Can be called from the NeatFi
     *      contract only.
     * @param maker - The address of the Order maker.
     * @param orderHash - The hash of the Order.
     * @param newPrice - The new price of the Order.
     */
    function increaseEnglishAuctionPrice(
        address maker,
        bytes32 orderHash,
        uint256 newPrice
    ) external onlyRole(AUTHORIZED_OPERATOR) {
        _increaseEnglishAuctionPrice(maker, orderHash, newPrice);
    }

    /**
     * @dev An external function to record a bid committment in native tokens
     *      for an English Auction Order. Can be called from the NeatFi
     *      contract only.
     * @param bidder - The address of the bidder.
     * @param orderHash - The hash of the Order.
     * @param bidValue - The value of the bid committment.
     */
    function bidForEnglishAuction(
        address bidder,
        bytes32 orderHash,
        uint256 bidValue
    ) external onlyRole(AUTHORIZED_OPERATOR) {
        _bidForEnglishAuction(bidder, orderHash, bidValue);
    }

    /**
     * @dev An external function to record a bid committment in native tokens
     *      for a Dutch Auction Order. Can be called from the NeatFi
     *      contract only.
     * @param bidder - The address of the bidder.
     * @param orderHash - The hash of the Order.
     * @param bidValue - The value of the bid committment.
     */
    function bidForDutchAuction(
        address bidder,
        bytes32 orderHash,
        uint256 bidValue
    ) external onlyRole(AUTHORIZED_OPERATOR) {
        _bidForDutchAuction(bidder, orderHash, bidValue);
    }

    /**
     * @dev An external function for the maker to approve the
     *      last bidder to claim the Order. Can be called from the NeatFi
     *      contract only.
     * @param orderHash - The hash of the Order.
     * @param maker - The address of the Order maker.
     */
    function approveLastBid(address maker, bytes32 orderHash)
        external
        onlyRole(AUTHORIZED_OPERATOR)
    {
        _approveLastBid(maker, orderHash);
    }

    /**
     * @dev An external function for the approved bidder to claim
     *      an Auction Order (English or Dutch). Can be called from the NeatFi
     *      contract only.
     * @param orderHash - The hash of the Order.
     * @param bidder - The address of the approved bidder.
     */
    function claimAuction(
        address bidder,
        bytes32 orderHash,
        bytes calldata data
    ) external onlyRole(AUTHORIZED_OPERATOR) {
        _claimAuction(bidder, orderHash, data);
    }

    /**
     * @dev An external function to retrieve the last bidder's address
     *      for a given Order. Can be called from the NeatFi
     *      contract only.
     * @param orderHash - The hash of the Order.
     * @return lastBidder -  The address of the last bidder.
     */
    function getLastBidderAddress(bytes32 orderHash)
        external
        view
        onlyRole(AUTHORIZED_OPERATOR)
        returns (address lastBidder)
    {
        return _getLastBidderAddress(orderHash);
    }

    /** Initializers */

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(PROTOCOL_ADMIN)
    {}

    function initialize(
        address neatFiProtocolStorageAddress,
        address assetTransferAddress
    ) public initializer onlyProxy {
        __UUPSUpgradeable_init();
        __AssetAuctionOperations_init(
            assetTransferAddress,
            neatFiProtocolStorageAddress
        );

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        name = "NeatFi Asset Auction Module";
        _setVersion("1.0.0");
    }
}
