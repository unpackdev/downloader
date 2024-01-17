// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./AggregatorV3Interface.sol";
import "./console.sol";
import "./Ownable.sol";

contract ChainlinkPriceConsumer is Ownable {
    AggregatorV3Interface public priceFeed;

    constructor() {
        address oracle = block.chainid == 5 ?
              0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
            : 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        
        priceFeed = AggregatorV3Interface(oracle);
    }
    
    function setOracle(address oracle) public onlyOwner {
        priceFeed = AggregatorV3Interface(oracle);
    }

    function getLatestPrice() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }
    
    function latestAnswer() external view returns (int256) {
        return getLatestPrice();
    }
}