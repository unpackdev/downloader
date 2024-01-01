// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "./Fixed256x18.sol";
import "./IPriceFeed.sol";
import "./IPriceOracleRETH.sol";
import "./ChainlinkPriceOracle.sol";

contract ChainlinkPriceOracleRETH is ChainlinkPriceOracle, IPriceOracleRETH {
    // --- Types ---

    using Fixed256x18 for uint256;

    // --- Immutables ---

    IPriceFeed public immutable override priceFeedETH;

    // --- Constructor ---

    constructor(
        AggregatorV3Interface priceAggregatorAddress_,
        IPriceFeed priceFeedETH_,
        uint256 deviation_,
        uint256 timeout_,
        uint256 targetDigits_,
        uint256 maxPriceDeviationFromPreviousRound_
    )
        ChainlinkPriceOracle(
            priceAggregatorAddress_,
            deviation_,
            timeout_,
            targetDigits_,
            maxPriceDeviationFromPreviousRound_
        )
    {
        if (address(priceFeedETH_) == address(0)) {
            revert InvalidPriceFeedETHAddress();
        }
        priceFeedETH = priceFeedETH_;
    }

    function _formatPrice(uint256 price, uint256 answerDigits) internal override returns (uint256) {
        (uint256 ethUsdPrice,) = priceFeedETH.fetchPrice();
        return super._formatPrice(price, answerDigits).mulDown(ethUsdPrice);
    }
}
