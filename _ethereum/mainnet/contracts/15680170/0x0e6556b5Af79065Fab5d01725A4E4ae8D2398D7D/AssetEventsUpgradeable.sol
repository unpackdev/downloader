// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./AssetStructsUpgradeable.sol";
import "./Initializable.sol";

/**
 * @title AssetEventsUpgradeable
 * @author NeatFi
 * @notice This contract holds the events for the protocol storage events
 *         of NeatFi.
 */
contract AssetEventsUpgradeable is Initializable, AssetStructsUpgradeable {
    /**
     * @dev Fired when an Order is created.
     * @param order - The Order struct record.
     * @param orderHash - The hash of the Order.
     */
    event OrderCreated(Order order, bytes32 orderHash);

    /**
     * @dev Fired when an Order status is changed.
     * @param order - The Order struct record.
     */
    event OrderStatusChanged(Order order);

    /**
     * @dev Fired when an Order start price is changed.
     * @param order - The Order struct record.
     */
    event OrderStartPriceChanged(Order order);

    /**
     * @dev Fired when an Order end price is changed.
     * @param order - The Order struct record.
     */
    event OrderEndPriceChanged(Order order);

    /**
     * @dev Fired when an Order expiration timestamp is changed.
     * @param order - The Order struct record.
     */
    event OrderExpirationTimeChanged(Order order);

    /* Initializers */

    function __AssetEvents_init() internal initializer {
        __AssetStructs_init_unchained();
        __AssetEvents_init_unchained();
    }

    function __AssetEvents_init_unchained() internal initializer {}
}
