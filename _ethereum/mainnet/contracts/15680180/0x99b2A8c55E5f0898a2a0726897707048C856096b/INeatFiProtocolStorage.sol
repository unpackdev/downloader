// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./AssetStructsUpgradeable.sol";
import "./AssetEnumsUpgradeable.sol";

/**
 * @title INeatFiProtocolStorage
 * @author NeatFi
 * @notice Interface to the {NeatFiProtocolStorage} storage operations
 *         contract of NeatFi.
 */
interface INeatFiProtocolStorage {
    /**
     * @notice Creates an Order in the NeatFi protocol storage contract.
     * @dev Called only from the NeatFi contract.
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
        AssetStructsUpgradeable.Token[] calldata tokens,
        AssetEnumsUpgradeable.AssetOrderType orderType,
        address maker,
        uint256 listingTime,
        uint256 expirationTime,
        uint256 startPrice,
        uint256 endPrice,
        bytes32 actorKey
    ) external returns (bytes32 orderHash);

    /**
     * @notice Retrieves an Order according to its hash.
     * @dev Called only from the NeatFi contract.
     * @param orderHash - The hash of the Order.
     * @return order - The Order struct record.
     */
    function getOrder(bytes32 orderHash)
        external
        view
        returns (AssetStructsUpgradeable.Order memory order);

    /**
     * @notice Retrieves the maker of an Order.
     * @dev Called only from the NeatFi contract.
     * @param orderHash - The hash of the Order.
     * @return maker - The address of the Order maker.
     */
    function getOrderMaker(bytes32 orderHash)
        external
        view
        returns (address payable maker);

    /**
     * @notice Retrieves a Token according to its hash.
     * @dev Called only from the NeatFi contract.
     * @param tokenHash - The hash of the Token.
     * @return The Token struct record.
     */
    function getToken(bytes32 tokenHash)
        external
        view
        returns (AssetStructsUpgradeable.Token memory);

    /**
     * @notice Checks the validity of the Order. The Order is invalied if any of
     *         the following conditions is not met:
     *         - the Order listing timestamp is bigger than the current block timestamp,
     *         - Order status is not OPEN,
     *         - Order expiration timestamp is smaller than the current block timestamp.
     * @dev Called only from the NeatFi contract.
     * @param orderHash - The hash of the Order.
     * @return The validity assessment result.
     */
    function isValidOrder(bytes32 orderHash) external returns (bool);

    /**
     * @notice Verifies the actor key for a given Order. This prevents other Actors
     *         interfering with an Order with a different actor key even if the
     *         actor key is known.
     * @dev Called only from the NeatFi contract.
     * @param orderHash - The hash of the Order.
     * @param actorKey - The actor key of the Actor.
     * @return The validity assessment result.
     */
    function isValidActorKey(bytes32 orderHash, bytes32 actorKey)
        external
        view
        returns (bool);

    /**
     * @notice Verifies that an address is the maker of an Order.
     * @dev Called only from the NeatFi contract.
     * @param orderHash - The hash of the Order.
     * @param maker - The address of the claimant maker.
     * @return The validity assessment result.
     */
    function isValidOwner(bytes32 orderHash, address maker)
        external
        view
        returns (bool);

    /**
     * @notice Changes the start price of an Order.
     * @dev Called only from the NeatFi contract.
     * @param orderHash - The hash of the Order.
     * @param newStartPrice - The new start price.
     */
    function changeOrderStartPrice(bytes32 orderHash, uint256 newStartPrice)
        external;

    /**
     * @notice Changes the end price of an Order.
     * @dev Called only from the NeatFi contract.
     * @param orderHash - The hash of the Order.
     * @param newEndPrice - The new end price.
     */
    function changeOrderEndPrice(bytes32 orderHash, uint256 newEndPrice)
        external;

    /**
     * @notice Changes the status of an Order.
     * @dev Called only from the NeatFi contract.
     * @param orderHash - The hash of the Order.
     * @param newStatus - The new status enum of an Order.
     *                    0 - OPEN,
     *                    1 - PROCESSING,
     *                    2 - EXPIRED,
     *                    3 - CANCELLED,
     *                    4 - CLOSED.
     */
    function changeOrderStatus(
        bytes32 orderHash,
        AssetEnumsUpgradeable.AssetOrderStatus newStatus
    ) external;

    /**
     * @notice Changes the expiration time  of an Order.
     * @dev Called only from the NeatFi contract.
     * @param orderHash - The hash of the Order.
     * @param newExpirationTime - The new expiration timestamp.
     */
    function changeOrderExpirationTime(
        bytes32 orderHash,
        uint256 newExpirationTime
    ) external;
}
