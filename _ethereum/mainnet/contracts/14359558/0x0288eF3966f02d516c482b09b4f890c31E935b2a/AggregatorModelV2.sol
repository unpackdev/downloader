// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @title dForce's AggregatorModelV2 Contract
 * @author dForce
 * @notice The aggregator model is a reorganization of the third-party price oracle,
 *          so it can be applied to the priceOracle contract price system
 */
abstract contract AggregatorModelV2 {
    /**
     * @notice Read the price of the asset from the delegate aggregator.
     */
    function getAssetPrice(address _asset) external virtual returns (uint256, uint8);

    /**
    * @notice represents the number of decimals the aggregator responses represent.
    */
    // function decimals() external view virtual returns (uint8);

    /**
    * @notice the version number representing the type of aggregator the proxy points to.
    */
    function version() external view virtual returns (uint256);
}