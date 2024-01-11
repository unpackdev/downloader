// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

// Get the latest ETH/USD price from chainlink price feed
import "AggregatorV3Interface.sol";

contract EthUsPriceConvert {

    uint256 immutable usdEntryFee;
    AggregatorV3Interface immutable ethUsdPriceFeed;

    constructor(
        address _priceFeedAddress,
        uint256 minumum_entry_fee
    ) {
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        usdEntryFee = minumum_entry_fee * (10**18);
    }

    /**
     * @notice Get the minimum funding amount which is $50
     */
    function getEntranceFee() external view returns (uint256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**10; // 18 decimals

        // $50, $2,000 / ETH
        // 50/2,000
        // 50 * 100000 / 2000
        uint256 costToEnter = (usdEntryFee * 10**18) / adjustedPrice;
        return costToEnter;
    }
}