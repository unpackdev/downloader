// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Initializable.sol";

/**
 * @title AssetAuctionStorageUpgradeable
 * @author NeatFi
 * @notice This contract holds the storage for the Asset Auction
 *         module of Neatfi.
 */
contract AssetAuctionStorageUpgradeable is Initializable {
    /**
     * @dev Maps the hash of the Order to the last bidder's address.
     */
    mapping(bytes32 => address) public lastBidderForOrder;

    /**
     * @dev An internal function to retrieve the last bidder's address
     *      for a given Order.
     * @param orderHash - The hash of the Order.
     * @return lastBidder - The address of the last bidder.
     */
    function _getLastBidderAddress(bytes32 orderHash)
        internal
        view
        returns (address lastBidder)
    {
        return lastBidderForOrder[orderHash];
    }

    /** Initializers */

    function __AssetAuctionStorage_init() internal initializer {
        __AssetAuctionStorage_init_unchained();
    }

    function __AssetAuctionStorage_init_unchained() internal initializer {}
}
