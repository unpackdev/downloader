// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./SafeMathUpgradeable.sol";

import "./AggregatorModelV2.sol";

import "./ICurve.sol";
import "./IDForceLending.sol";

contract LPCurveAggregatorModel is AggregatorModelV2 {
    using SafeMathUpgradeable for uint256;

    uint8 internal constant doubleDecimals = 36;

    /**
     * @notice Reads the current answer from aggregator delegated to.
     * @param _assetPrice:The price of the asset aggregator (scaled by decimals), zero under unexpected case.
     * @param _decimals:Asset price decimals
     */
    function getAssetPrice(address _asset) external override returns (uint256 _assetPrice, uint8 _decimals) {
        IiToken _iToken = IiToken(_asset);
        _assetPrice = _getPrice(_iToken.controller().priceOracle(), ICurveMeta(_iToken.underlying()));
        _decimals = _iToken.decimals();
        _decimals = doubleDecimals > _decimals ? doubleDecimals - _decimals : 0;
    }

    /**
    * @notice the version number representing the type of aggregator the proxy points to.
    * @return The aggregator version is uint256(-1).
    */
    function version() external view override returns (uint256) {
        return uint256(-1);
    }

    /**
     * @notice Retrieves price of an asset.
     * @dev Get price for an asset.
     * @param _priceOracle address of priceOracle to get asset price.
     * @param _lpCurve Asset for which to get the price.
     * @return The price of the asset (scaled by decimals), zero under unexpected case.
     */
    function getLpTokenPrice(IPriceOracle _priceOracle, ICurveMeta _lpCurve) external returns (uint256) {
        return _getPrice(_priceOracle, _lpCurve);
    }

    /**
     * @notice Retrieves price of an asset.
     * @dev Get price for an asset.
     * @param _priceOracle address of priceOracle to get asset price.
     * @param _lpCurve LP asset for which to get the price.
     * @return The price of the asset (scaled by decimals), zero under unexpected case.
     */
    function _getPrice(IPriceOracle _priceOracle, ICurveMeta _lpCurve) internal returns (uint256) {
        IiToken _coin = IiToken(_lpCurve.coins(0));
        return _priceOracle.getUnderlyingPrice(_coin).mul(_lpCurve.get_virtual_price()) / 10 ** uint256(doubleDecimals).sub(uint256(_coin.decimals()));
    }
}