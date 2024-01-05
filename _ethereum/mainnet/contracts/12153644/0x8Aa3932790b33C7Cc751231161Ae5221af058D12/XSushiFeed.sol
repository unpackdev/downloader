pragma solidity ^0.5.16;

import "./SafeMath.sol";

interface Feed {
    function decimals() external view returns (uint8);
    function latestAnswer() external view returns (uint);
}

interface IXSushiExchangeRate {
    function getExchangeRate() external view returns (uint256);
}

contract XSushiFeed is Feed {
    using SafeMath for uint;

    IXSushiExchangeRate public xSushiExchangeRate;
    Feed public sushiFeed;
    Feed public ethFeed;

    constructor(IXSushiExchangeRate _xSushiExchangeRate, Feed _sushiFeed, Feed _ethFeed) public {
        xSushiExchangeRate = _xSushiExchangeRate;
        sushiFeed = _sushiFeed;
        ethFeed = _ethFeed;
    }

    function decimals() public view returns(uint8) {
        return sushiFeed.decimals();
    }

    function latestAnswer() public view returns (uint) {
        uint exchangeRate = xSushiExchangeRate.getExchangeRate();
        return sushiFeed.latestAnswer()
            .mul(ethFeed.latestAnswer())
            .div(10**uint256(ethFeed.decimals()))
            .mul(exchangeRate)
            .div(10**18);
    }

}