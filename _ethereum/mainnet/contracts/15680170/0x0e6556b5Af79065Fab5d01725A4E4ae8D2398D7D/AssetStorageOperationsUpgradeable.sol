// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./AssetMappingsUpgradeable.sol";
import "./AssetTypehasheConstantsUpgradeable.sol";
import "./AssetStorageSettingsUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./RoleConstantsUpgradeable.sol";
import "./AddressVerifier.sol";
import "./LimitsVerifier.sol";

/**
 * @title AssetStorageOperationsUpgradeable
 * @author NeatFi
 * @notice This contract implements the operations for the NeatFi
 *         protocol storage.
 */
contract AssetStorageOperationsUpgradeable is
    RoleConstantsUpgradeable,
    AssetStorageSettingsUpgradeable,
    AssetTypehasheConstantsUpgradeable,
    AssetMappingsUpgradeable,
    AddressVerifier,
    LimitsVerifier,
    AccessControlUpgradeable
{
    /**
     * @dev An internal function to generate the hash of a single Token asset.
     * @param token - Token asset struct.
     * @return singleTokenHash - The generated hash of the Token asset.
     */
    function _hashSingleToken(Token memory token)
        internal
        returns (bytes32 singleTokenHash)
    {
        singleTokenHash = keccak256(
            abi.encode(
                TOKEN_TYPEHASH,
                token.tokenContract,
                token.tokenId,
                token.amount,
                token.tokenType
            )
        );

        tokenInfo[singleTokenHash] = token;

        return singleTokenHash;
    }

    /**
     * @dev An internal function to generate the hash of a batch of
     *      Token assets.
     * @param tokens - The array of Token assets.
     * @return tokenHashes - The generated hashes of the Token assets.
     */
    function _hashTokens(Token[] memory tokens)
        internal
        returns (bytes32[] memory tokenHashes)
    {
        tokenHashes = new bytes32[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            require(
                isValidContractAddress(tokens[i].tokenContract),
                "AssetStorageOperationsUpgradeable:_hashTokens: one of the Token contracts in the batch does not exist."
            );

            tokenHashes[i] = _hashSingleToken(
                Token(
                    tokens[i].tokenContract,
                    tokens[i].tokenId,
                    tokens[i].amount,
                    tokens[i].tokenType
                )
            );
        }

        return tokenHashes;
    }

    /**
     * @dev An internal function to generate the hash of an Order.
     * @param order - The Order struct.
     * @return orderHash - The generated hash of the Token asset.
     */
    function _hashOrder(Order memory order)
        internal
        pure
        returns (bytes32 orderHash)
    {
        return
            keccak256(
                abi.encode(
                    ORDER_TYPEHASH,
                    order.tokenHashes,
                    order.maker,
                    order.orderType,
                    order.listingTime,
                    order.expirationTime,
                    order.startPrice,
                    order.endPrice,
                    order.salt,
                    order.status
                )
            );
    }

    /**
     * @dev An internal function to create an Order struct record.
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
    function _makeOrder(
        Token[] calldata tokens,
        address payable maker,
        AssetOrderType orderType,
        uint256 listingTime,
        uint256 expirationTime,
        uint256 startPrice,
        uint256 endPrice,
        bytes32 actorKey
    ) internal returns (bytes32 orderHash) {
        require(
            tokens.length >= 1 && tokens.length <= maxTokenNumber,
            "AssetStorageOperationsUpgradeable::_makeOrder: asset number increases the maximum allowed."
        );

        require(
            listingTime >= block.timestamp,
            "AssetStorageOperationsUpgradeable::_makeOrder: wrong listing time."
        );

        bytes32[] memory tokenHashes = _hashTokens(tokens);

        bytes32 salt = keccak256(abi.encode(maker, block.timestamp, actorKey));

        Order memory o = Order(
            tokenHashes,
            maker,
            orderType,
            listingTime,
            expirationTime,
            startPrice,
            endPrice,
            salt,
            AssetOrderStatus.OPEN,
            actorKey
        );

        orderHash = _hashOrder(o);
        orderInfo[orderHash] = o;

        emit OrderCreated(o, orderHash);

        return orderHash;
    }

    /**
     * @dev Checks the validity of the Order. The Order is invalied if any of
     *         the following conditions is not met:
     *         - the Order listing timestamp is bigger than the current block timestamp,
     *         - Order status is not OPEN,
     *         - Order expiration timestamp is smaller than the current block timestamp.
     * @param orderHash - The hash of the Order.
     * @return The validity assessment result.
     */
    function _isValidOrder(bytes32 orderHash) internal returns (bool) {
        Order storage order = orderInfo[orderHash];

        require(
            block.timestamp > order.listingTime,
            "AssetStorageOperationsUpgradeable::_isValidOrder: invalid order - order is not ready for operations."
        );

        require(
            order.status == AssetOrderStatus.OPEN,
            "AssetStorageOperationsUpgradeable::_isValidOrder: invalid order - order status is not OPEN"
        );

        /// Order must not be EXPIRED.
        if (
            order.expirationTime != 0 && block.timestamp > order.expirationTime
        ) {
            order.status = AssetOrderStatus.EXPIRED;
            emit OrderStatusChanged(order);
            return false;
        }

        return true;
    }

    /**
     * @dev Verifies the actor key for a given Order. This prevents other Actors
     *         interfering with an Order with a different actor key even if the
     *         actor key is known.
     * @param orderHash - The hash of the Order.
     * @param actorKey - The actor key of the Actor.
     * @return The validity assessment result.
     */
    function _isValidActorKey(bytes32 orderHash, bytes32 actorKey)
        internal
        view
        returns (bool)
    {
        Order storage order = orderInfo[orderHash];

        require(
            actorKey == order.actorKey,
            "AssetStorageOperationsUpgradeable::_isValidActorKey: order and actor key mismtach."
        );

        return true;
    }

    /**
     * @dev Verifies that an address is the maker of an Order.
     * @param orderHash - The hash of the Order.
     * @param maker - The address of the claimant maker.
     * @return The validity assessment result.
     */
    function _isValidOwner(bytes32 orderHash, address payable maker)
        internal
        view
        returns (bool)
    {
        Order storage order = orderInfo[orderHash];
        require(
            order.maker == maker,
            "AssetStorageOperationsUpgradeable::_isValidOwner: claimant address is not the order maker."
        );

        return true;
    }

    /**
     * @dev Retrieves an Order according to its hash.
     * @param orderHash - The hash of the Order.
     * @return order - The Order struct record.
     */
    function _getOrder(bytes32 orderHash)
        internal
        view
        returns (Order storage order)
    {
        return orderInfo[orderHash];
    }

    /**
     * @dev Retrieves the maker of the Order.
     * @param orderHash - The hash of the Order.
     * @return maker - The address of the Order maker.
     */
    function _getOrderMaker(bytes32 orderHash)
        internal
        view
        returns (address payable maker)
    {
        Order storage order = orderInfo[orderHash];

        return order.maker;
    }

    /**
     * @dev Retrieves a Token struct record according to its hash.
     * @param tokenHash - The hash of the Token.
     * @return token - The Token struct record.
     */
    function _getToken(bytes32 tokenHash)
        internal
        view
        returns (Token storage token)
    {
        return tokenInfo[tokenHash];
    }

    /**
     * @dev Changes the start price of an Order.
     * @param orderHash - The hash of the Order.
     * @param newStartPrice - The new start price.
     */
    function _changeOrderStartPrice(bytes32 orderHash, uint256 newStartPrice)
        internal
        isWithinLimits(newStartPrice)
    {
        Order storage order = orderInfo[orderHash];

        order.startPrice = newStartPrice;

        emit OrderStartPriceChanged(order);
    }

    /**
     * @dev Changes the end price of an Order.
     * @param orderHash - The hash of the Order.
     * @param newEndPrice - The new end price.
     */
    function _changeOrderEndPrice(bytes32 orderHash, uint256 newEndPrice)
        internal
        isWithinLimits(newEndPrice)
    {
        Order storage order = orderInfo[orderHash];

        order.endPrice = newEndPrice;

        emit OrderEndPriceChanged(order);
    }

    /**
     * @dev Changes the status of an Order.
     * @param orderHash - The hash of the Order.
     * @param newStatus - The new status enum of an Order.
     *                    0 - OPEN,
     *                    1 - PROCESSING,
     *                    2 - EXPIRED,
     *                    3 - CANCELLED,
     *                    4 - CLOSED.
     */
    function _changeOrderStatus(bytes32 orderHash, AssetOrderStatus newStatus)
        internal
    {
        Order storage order = orderInfo[orderHash];

        order.status = newStatus;

        emit OrderStatusChanged(order);
    }

    /**
     * @dev Changes the expiration time  of an Order.
     * @param orderHash - The hash of the Order.
     * @param newExpirationTime - The new expiration timestamp.
     */
    function _changeOrderExpirationTime(
        bytes32 orderHash,
        uint256 newExpirationTime
    ) internal {
        Order storage order = orderInfo[orderHash];

        order.expirationTime = newExpirationTime;

        emit OrderExpirationTimeChanged(order);
    }

    /** Initializers */

    function __AssetStorageOperations_init(uint256 maxTokenNumber)
        internal
        initializer
    {
        __RoleConstants_init();
        __AssetEnums_init();
        __AssetStorageSettings_init(maxTokenNumber);
        __AssetTypehasheConstants_init();
        __AssetMappings_init();
        __AccessControl_init();
    }
}
