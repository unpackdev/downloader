pragma solidity ^0.6.2;

import "./IPriceFeed.sol";
import "./SafeMath.sol";

contract PriceFeedMock {

    using SafeMath for uint;

    IPriceFeed internal priceFeed;
    bool internal mockMode;
    uint internal adjustmentValue;

    constructor(address _priceFeed) public {
        priceFeed = IPriceFeed(_priceFeed);
        mockMode = false;
    }

    function mock(uint _adjustmentValue) public {
        mockMode = true;
        adjustmentValue = _adjustmentValue;
    }

    function getLatestPriceToken0() public view returns (uint) {
        if (mockMode) {
            return priceFeed.getLatestPriceToken0().sub(adjustmentValue) ;
        }
        return priceFeed.getLatestPriceToken0();
    }

    function getLatestPriceToken1() public view returns (uint) {
        if (mockMode) {
            return priceFeed.getLatestPriceToken1().sub(adjustmentValue);
        }
        return priceFeed.getLatestPriceToken1();
    }
}