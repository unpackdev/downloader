// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./AssetStorageOperationsUpgradeable.sol";
import "./UUPSUpgradeable.sol";

/**
 * @title NeatFiProtocolStorageV1
 * @author NeatFi
 * @notice This contract implements the external facing functionality
 *         for the Protocol Storage contract of NeatFi.
 */
contract NeatFiProtocolStorageV1 is
    AssetStorageOperationsUpgradeable,
    UUPSUpgradeable
{
    string private name;
    string private currentVersion;

    /**
     * @dev Sets the version for the current implementation of this contract.
     */
    function _setVersion(string memory newVersion) internal {
        currentVersion = newVersion;
    }

    /**
     *
     * @dev An external function to regulate the maximum number of unique
     *      Token assets in an Order. Can be executed by a Protocol Admin only.
     * @param newMaxTokenNumber - new maximum number of Token assets.
     */
    function setMaxTokenNumber(uint256 newMaxTokenNumber)
        external
        onlyRole(PROTOCOL_ADMIN)
    {
        maxTokenNumber = newMaxTokenNumber;
    }

    /**
     * @dev An external function to create an Order struct record. Can be
     *      called by the NeatFi contract only.
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
     * @param endPrice - The end price of the Order.
     * @param actorKey - The actor key of the Actor contract through which the Order
     *                   is being created.
     * @return orderHash - The hash of the created Order.
     */
    function makeOrder(
        Token[] calldata tokens,
        AssetOrderType orderType,
        address payable maker,
        uint256 listingTime,
        uint256 expirationTime,
        uint256 startPrice,
        uint256 endPrice,
        bytes32 actorKey
    ) external onlyRole(AUTHORIZED_OPERATOR) returns (bytes32 orderHash) {
        orderHash = _makeOrder(
            tokens,
            maker,
            orderType,
            listingTime,
            expirationTime,
            startPrice,
            endPrice,
            actorKey
        );

        return orderHash;
    }

    /**
     * @dev An external function to retrive an Order according to its hash. Can be
     *      called by the NeatFi contract only.
     * @param orderHash - The hash of the Order.
     * @return order - The Order struct record.
     */
    function getOrder(bytes32 orderHash)
        external
        view
        onlyRole(AUTHORIZED_OPERATOR)
        returns (Order memory order)
    {
        return _getOrder(orderHash);
    }

    /**
     * @dev An external function to retrieve the Order maker. Can
     *      be called by the NeatFi contract only.
     * @param orderHash - The hash of the Order.
     * @return maker - The address of the Order maker.
     */
    function getOrderMaker(bytes32 orderHash)
        external
        view
        onlyRole(AUTHORIZED_OPERATOR)
        returns (address payable maker)
    {
        return _getOrderMaker(orderHash);
    }

    /**
     * @dev An external function to retrive a Token asset according to its hash.
     *      Can be called by the NeatFi contract only.
     * @param tokenHash - The hash of the Token.
     * @return token - The Token struct record.
     */
    function getToken(bytes32 tokenHash)
        external
        view
        onlyRole(AUTHORIZED_OPERATOR)
        returns (Token memory token)
    {
        return _getToken(tokenHash);
    }

    /**
     * @dev An external function to check the validity of the Order.
     *      Can be called by the NeatFi contract only.
     * @param orderHash - The hash of the Order.
     * @return The validity assessment result.
     */
    function isValidOrder(bytes32 orderHash)
        external
        onlyRole(AUTHORIZED_OPERATOR)
        returns (bool)
    {
        return _isValidOrder(orderHash);
    }

    /**
     * @dev An external function to verify the actor key for a given Order.
     *      This prevents other Actors interfering with an Order with a different
     *      actor key even if the actor key is known.
     *      Can be called by the NeatFi contract only.
     * @param orderHash - The hash of the Order.
     * @param actorKey - The actor key of the Actor.
     * @return The validity assessment result.
     */
    function isValidActorKey(bytes32 orderHash, bytes32 actorKey)
        external
        view
        onlyRole(AUTHORIZED_OPERATOR)
        returns (bool)
    {
        return _isValidActorKey(orderHash, actorKey);
    }

    /**
     * @dev An external function to verify that an address is
     *      the maker of an Order.
     *      Can be called by the NeatFi contract only.
     * @param orderHash - The hash of the Order.
     * @param maker - The address of the claimant maker.
     * @return The validity assessment result.
     */
    function isValidOwner(bytes32 orderHash, address payable maker)
        external
        view
        onlyRole(AUTHORIZED_OPERATOR)
        returns (bool)
    {
        return _isValidOwner(orderHash, maker);
    }

    /**
     * @dev Changes the start price of an Order. Can be called
     *      by the NeatFi contract only.
     * @param orderHash - The hash of the Order.
     * @param newStartPrice - The new start price.
     */
    function changeOrderStartPrice(bytes32 orderHash, uint256 newStartPrice)
        external
        onlyRole(AUTHORIZED_OPERATOR)
    {
        _changeOrderStartPrice(orderHash, newStartPrice);
    }

    /**
     * @dev Changes the end price of an Order. Can be called
     *      by the NeatFi contract only.
     * @param orderHash - The hash of the Order.
     * @param newEndPrice - The new end price.
     */
    function changeOrderEndPrice(bytes32 orderHash, uint256 newEndPrice)
        external
        onlyRole(AUTHORIZED_OPERATOR)
    {
        _changeOrderEndPrice(orderHash, newEndPrice);
    }

    /**
     * @dev An external function to change the Order status. Can be called
     *      by the NeatFi contract only.
     * @param orderHash - The hash of the Order.
     * @param newStatus - The new status enum of an Order.
     */
    function changeOrderStatus(bytes32 orderHash, AssetOrderStatus newStatus)
        external
        onlyRole(AUTHORIZED_OPERATOR)
    {
        _changeOrderStatus(orderHash, newStatus);
    }

    /**
     * @dev An external function to change the expiration time  of an Order.
     *      Can be called by the NeatFi contract only.
     * @param orderHash - The hash of the Order.
     * @param newExpirationTime - The new expiration timestamp.
     */
    function changeOrderExpirationTime(
        bytes32 orderHash,
        uint256 newExpirationTime
    ) external onlyRole(AUTHORIZED_OPERATOR) {
        _changeOrderExpirationTime(orderHash, newExpirationTime);
    }

    /** Initializers */

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(PROTOCOL_ADMIN)
    {}

    function initialize(uint256 maxTokenNumberValue)
        public
        initializer
        onlyProxy
    {
        __UUPSUpgradeable_init();
        __AssetStorageOperations_init(maxTokenNumberValue);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        name = "NeatFi Protocol Storage Layer";
        _setVersion("1.0.0");
    }
}
