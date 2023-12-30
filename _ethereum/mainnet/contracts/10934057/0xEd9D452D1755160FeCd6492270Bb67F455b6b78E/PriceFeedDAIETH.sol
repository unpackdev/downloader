pragma solidity ^0.6.2;

import "./AggregatorV3Interface.sol";
import "./DSMath.sol";
import "./Extensions.sol";
import "./IPriceFeed.sol";

contract PriceFeedDAIETH is IPriceFeed, DSMath, Extensions {
    AggregatorV3Interface internal priceFeed;

    constructor() public {
        priceFeed = AggregatorV3Interface(0x773616E4d11A78F511299002da57A0a94577F1f4);
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
        return convertIntToUint(price);
    }

    function getLatestPriceToken1() public view override returns (uint) { // Use Wad  for DAI/ETH
        return wdiv(1 ether, getLatestPriceToken0());
    }
}