// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Initializable.sol";

/**
 * @title AssetSwapEventsUpgradeable
 * @author NeatFi
 * @notice This contract holds the events for the Asset Swap module of NeatFi.
 */
contract AssetSwapEventsUpgradeable is Initializable {
    /**
     * @dev Fired when a Bid type Order is created for a Swap Order.
     * @param orderHash - The hash of the Order.
     * @param bidHash - The hash of the Bid type Order.
     */
    event BidForOrder(bytes32 orderHash, bytes32 bidHash);

    /** Initializers */

    function __AssetSwapEvents_init() internal initializer {
        __AssetSwapEvents_init_unchained();
    }

    function __AssetSwapEvents_init_unchained() internal initializer {}
}
