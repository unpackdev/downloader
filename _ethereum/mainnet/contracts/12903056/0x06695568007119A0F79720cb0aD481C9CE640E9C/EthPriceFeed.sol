pragma solidity ^0.8.0;

import "./AggregatorV3Interface.sol";

abstract contract EthPriceFeed {

    //https://docs.chain.link/docs/ethereum-addresses/
    function getExchangePrice(address pairProxyAddress) public view returns (int) {
        (uint80 roundID,int price,uint startedAt,uint timeStamp,uint80 answeredInRound) = AggregatorV3Interface(pairProxyAddress).latestRoundData();
        return price;
    }
}
