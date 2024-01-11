//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

/**
 * @title IEurPriceFeed
 * @author Protofire
 * @dev Interface to be implemented by any EurPriceFeed logic contract used in the protocol.
 *
 */
interface IEurPriceFeed {
    /**
     * @dev Gets the feed of the asset
     *
     * @param _asset address of asset to get the price feed.
     */
    function getAssetFeed(address _asset) external view returns (address);
}
