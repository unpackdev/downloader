// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "./SafeMathUpgradeable.sol";
import "./ERC20Upgradeable.sol";

import "./PriceOracle.sol";
import "./CToken.sol";
import "./CErc20.sol";

import "./AggregatorV3Interface.sol";

import "./BasePriceOracle.sol";

/**
 * @title FixedEurPriceOracle
 * @notice Returns fixed prices of 1 EUR in terms of ETH for all tokens (expected to be used under a `MasterPriceOracle`).
 * @dev Implements `PriceOracle` and `BasePriceOracle`.
 * @author David Lucid <david@rari.capital> (https://github.com/davidlucid)
 */
contract FixedEurPriceOracle is PriceOracle, BasePriceOracle {
    using SafeMathUpgradeable for uint256;

    /**
     * @notice Chainlink ETH/USD price feed contracts.
     */
    AggregatorV3Interface public constant ETH_USD_PRICE_FEED = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    /**
     * @notice Chainlink EUR/USD price feed contracts.
     */
    AggregatorV3Interface public constant EUR_USD_PRICE_FEED = AggregatorV3Interface(0xb49f677943BC038e9857d61E7d053CaA2C1734C1);

    /**
     * @dev Internal function returning the price in ETH of `underlying`.
     */
    function _price(address underlying) internal view returns (uint) {
        // Get ETH/USD price from Chainlink
        (, int256 ethUsdPrice, , , ) = ETH_USD_PRICE_FEED.latestRoundData();
        if (ethUsdPrice <= 0) return 0;

        // Get EUR/USD price from Chainlink
        (, int256 eurUsdPrice, , , ) = EUR_USD_PRICE_FEED.latestRoundData();
        if (eurUsdPrice <= 0) return 0;

        // Return EUR/ETH price = EUR/USD price / ETH/USD price
        return uint256(eurUsdPrice).mul(1e18).div(uint256(ethUsdPrice));
    }

    /**
     * @dev Returns the price in ETH of `underlying` (implements `BasePriceOracle`).
     */
    function price(address underlying) external override view returns (uint) {
        return _price(underlying);
    }

    /**
     * @notice Returns the price in ETH of the token underlying `cToken`.
     * @dev Implements the `PriceOracle` interface for Fuse pools (and Compound v2).
     * @return Price in ETH of the token underlying `cToken`, scaled by `10 ** (36 - underlyingDecimals)`.
     */
    function getUnderlyingPrice(CToken cToken) external override view returns (uint) {
        // Get underlying token address
        address underlying = CErc20(address(cToken)).underlying();

        // Format and return price
        // Comptroller needs prices to be scaled by 1e(36 - decimals)
        // Since `_price` returns prices scaled by 18 decimals, we must scale them by 1e(36 - 18 - decimals)
        return _price(underlying).mul(1e18).div(10 ** uint256(ERC20Upgradeable(underlying).decimals()));
    }
}