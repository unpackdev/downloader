// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./Initializable.sol";
import "./IAggregatorV3.sol";
import "./FixedPointMathLib.sol";

abstract contract PriceOracleUpgradeable is Initializable {
    using FixedPointMathLib for uint256;

    event SetPriceFeed(address token, PriceFeed priceFeed);
    event SetForexPriceFeed(address forexPriceFeed);

    struct PriceFeed {
        IAggregatorV3 usdAggregator;
        uint96 multiplier;
        uint256 price; // in usd, decimals 18
    }

    IAggregatorV3 internal _forexPriceFeed;
    mapping(address => PriceFeed) internal _priceFeeds;

    function __ChainLinkPriceOracle_init() internal onlyInitializing {
        __ChainLinkPriceOracle_init_unchained();
    }

    function __ChainLinkPriceOracle_init_unchained() internal onlyInitializing {}

    function getTokenUsdAmount(address token_, uint256 usdAmount_) external view returns (uint256) {
        return _getTokenUsdAmount(token_, usdAmount_);
    }

    function getTokenPrice(address token_) external view returns (uint256) {
        return _getUsdTokenPrice(token_);
    }

    // usdAmount: decimals 18
    function _getTokenUsdAmount(address token_, uint256 usdAmount) internal view returns (uint256) {
        uint256 usdPrice = _getUsdTokenPrice(token_);
        return usdAmount.mulDivUp(_priceFeeds[token_].multiplier, usdPrice);
    }

    function _getUsdAmount(address token, uint256 amount) internal view returns (uint256) {
        uint256 price = _getUsdTokenPrice(token); // decimals 18
        uint256 multiplier = _priceFeeds[token].multiplier;

        if (multiplier != 1e18) amount = (amount * 1e18) / multiplier; // decimals dynamic

        return (amount * price) / 1 ether;
    }

    function _getUsdTokenPrice(address token) internal view returns (uint256) {
        IAggregatorV3 usdAggregator = _priceFeeds[token].usdAggregator;
        if (usdAggregator != IAggregatorV3(address(0))) {
            (, int256 price, , , ) = usdAggregator.latestRoundData();
            return uint256(price * 1e10);
        }
        return _priceFeeds[token].price;
    }

    function _getFiatPrice() internal view returns (uint256) {
        (, int256 price, , , ) = _forexPriceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function _setPriceFeeds(address token_, PriceFeed memory priceFeed_) internal {
        _priceFeeds[token_] = priceFeed_;
        emit SetPriceFeed(token_, priceFeed_);
    }

    function _setForexPriceFeed(address forexPriceFeed_) internal {
        _forexPriceFeed = IAggregatorV3(forexPriceFeed_);
        emit SetForexPriceFeed(address(forexPriceFeed_));
    }

    uint256[49] private __gap;
}
