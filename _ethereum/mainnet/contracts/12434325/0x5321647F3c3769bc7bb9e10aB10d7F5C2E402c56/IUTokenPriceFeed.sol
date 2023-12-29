//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

/**
 * @title IUtilTokenPriceFeed
 * @author Protofire
 * @dev Interface to be implemented by any UtilityToken price feed logic contract used in the protocol.
 *
 */
interface IUTokenPriceFeed {
    /**
     * @dev Gets the price a `_asset` in UtilityToken.
     *
     * @param _asset address of asset to get the price.
     */
    function getPrice(address _asset) external returns (uint256);

    /**
     * @dev Gets how many UtilityToken represents the `_amount` of `_asset`.
     *
     * @param _asset address of asset to get the amount.
     * @param _amount amount of `_asset`.
     */
    function calculateAmount(address _asset, uint256 _amount) external view returns (uint256);
}
