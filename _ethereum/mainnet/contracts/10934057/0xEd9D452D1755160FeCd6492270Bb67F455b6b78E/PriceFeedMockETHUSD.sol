pragma solidity ^0.6.2;

import "./Ownable.sol";
import "./AggregatorV3Interface.sol";
import "./Extensions.sol";
import "./DSMath.sol";
import "./IPriceFeed.sol";

contract PriceFeedMockETHUSD is Extensions, DSMath, Ownable {

    bool public mockMode;
    uint public adjustmentValue;
    AggregatorV3Interface public priceFeed;

    constructor() public {
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        mockMode = false;
        adjustmentValue = 0;
    }

    function setOracleAddress(address _oracle) public onlyOwner {
        require(address(priceFeed) != _oracle, "Price Feeder ETH/USD : Already set.");
        priceFeed = AggregatorV3Interface(_oracle);
    }

    function unmock() public onlyOwner {
        mockMode = false;
    }

    function mock(uint _adjustmentValue) public onlyOwner {
        mockMode = true;
        adjustmentValue = _adjustmentValue;
    }

    function getLatestPriceToken0() public view returns (uint) {
        if (mockMode) {
            return sub(getOraclePriceToken0(), adjustmentValue);
        }
        return getOraclePriceToken0();
    }

    function getLatestPriceToken1() public view returns (uint) {
        if (mockMode) {
            return sub(getOraclePriceToken1(), adjustmentValue);
        }
        return getOraclePriceToken1();
    }

    function getOraclePriceToken0() internal view returns (uint) {
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

    function getOraclePriceToken1() internal view returns (uint) { // Use Wad for ETH/USD
        return wdiv(1 ether, getOraclePriceToken0());
    }
}