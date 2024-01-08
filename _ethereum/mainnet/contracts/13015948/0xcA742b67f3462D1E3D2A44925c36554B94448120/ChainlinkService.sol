pragma solidity >=0.5.0 <0.7.0;
import "./AggregatorV3Interface.sol";

contract ChainlinkService {  
  
    function getLatestPrice(address feedAddress) 
        public 
        view 
        returns (int, uint, uint8) 
    {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(feedAddress);
        ( ,int price, ,uint timeStamp, ) = priceFeed.latestRoundData();
        uint8 decimal = priceFeed.decimals();
        return (price, timeStamp, decimal);
    }
}