pragma solidity ^0.6.2;

import "./AggregatorV3Interface.sol";
import "./DSMath.sol";
import "./Extensions.sol";
import "./IPriceFeed.sol";

contract PriceFeedETHUSD is IPriceFeed, DSMath, Extensions {
    AggregatorV3Interface internal priceFeed;

    constructor() public {
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    }

    function getLatestPriceToken0() public view override returns (uint) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        require(timeStamp > 0, "Round not complete");
        return mul(convertIntToUint(price), 10 ** 10); // Transform to wad
    }

    function getLatestPriceToken1() public view override returns (uint) { // Use Wad  for ETH/USD
        return wdiv(1 ether, getLatestPriceToken0());
    }
}