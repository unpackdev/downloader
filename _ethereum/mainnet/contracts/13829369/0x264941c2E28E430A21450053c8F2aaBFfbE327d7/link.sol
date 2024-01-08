// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function phaseId() external view returns (uint16);
  function latestRound() external view returns (uint256);
  function latestAnswer() external view returns (uint256);
  function latestTimestamp() external view returns (uint256);

}

interface HistoricalPriceConsumerV3 {
    function getHistoricalPrice(uint80 roundId) external view returns (int256); 
    function getLatestPrice() external view returns (int);
    function getPriceAfterTimestamp(uint timeStamp) external view returns (int256);
    function findBlockSamePhase(uint timeStamp, uint80 phaseOffset, uint80 start, uint80 mid, uint80 end) external view returns (uint80);
    function getLatestPriceX1e6() external view returns (int);
}



contract HistoricalPriceConsumerV3_1 {

    /**
     * Network: Mainnet
     * Aggregator: ETH/USD
     * Address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
     
     * Network: Kovan
     * Aggregator: ETH/USD
     * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331

     * Network: Rinkeby
     * Aggregator: ETH/USD
     * Address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
     */
     
    /**
     * Returns historical price for a round id.
     * roundId is NOT incremental. Not all roundIds are valid.
     * You must know a valid roundId before consuming historical data.
     *
     * ROUNDID VALUES:
     *    InValid:      18446744073709562300
     *    Valid:        18446744073709562301
     *    
     * @dev A timestamp with zero value means the round is not complete and should not be used.
     */
    function getHistoricalPrice(AggregatorV3Interface priceFeed, uint80 roundId) public view returns (int256) {
        (
            uint80 id, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.getRoundData(roundId);
        require(timeStamp > 0, "Round not complete");
        return price;
    }

    function getLatestPrice(AggregatorV3Interface priceFeed) public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }
    
    function getPriceAfterTimestamp(AggregatorV3Interface priceFeed, uint timeStamp) public view returns (int256) {
        uint80 end = uint80(priceFeed.latestRound()) % (priceFeed.phaseId() * 2 ** 64);
        uint80 phaseOffset = priceFeed.phaseId() * 2 ** 64;        
        uint80 roundID = findBlockSamePhase(priceFeed, timeStamp, phaseOffset, 1, (end + 1) / 2, end );
        return getHistoricalPrice(priceFeed, roundID);
    }

    /*
      Binary search within current phase
      
      Failure modes:
      1. Block wanted is at start of new phase
      2. Too many incomplete rounds 
    */
    function findBlockSamePhase(AggregatorV3Interface priceFeed, uint timeStamp, uint80 phaseOffset, uint80 start, uint80 mid, uint80 end) public view returns (uint80) {    
        require(end >= mid + 1, "Block not found");

        ( , , , uint timeStamp_2, ) = priceFeed.getRoundData(mid + phaseOffset);
        ( , , , uint timeStamp_3, ) = priceFeed.getRoundData(end + phaseOffset);
        if (timeStamp_2 == 0) return findBlockSamePhase(priceFeed, timeStamp, phaseOffset, start, mid + 1, end);
        if (timeStamp_3 == 0) return findBlockSamePhase(priceFeed, timeStamp, phaseOffset, start, mid, end - 1);

        if (end == mid + 1) {
          if ((timeStamp_3 >= timeStamp) && ( timeStamp_2 < timeStamp )) {
            return phaseOffset + end;
          }            
        }
        
        require(timeStamp_3 >= timeStamp, "Block not found");                
        require(end > start             , "Block not found");                
        if (timeStamp_2 >= timeStamp) return findBlockSamePhase(priceFeed, timeStamp, phaseOffset, start, (start+mid) / 2, mid); 
        else                          return findBlockSamePhase(priceFeed, timeStamp, phaseOffset, mid,   (mid + end) / 2, end);            
    }
    
    // Chainlink returns 8 decimal place, this normalises it to 1e6 convention in this contract
    // Note: Chainlink prices are signed
    function getLatestPriceX1e6(AggregatorV3Interface priceFeed) public view returns (int) {
      return getLatestPrice(priceFeed) / 1e2;
    }
}



contract HistoricalPriceConsumerV3_RATIO {

    /**
     * Network: Mainnet
     * Aggregator: ETH/USD
     * Address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
     **/
     
    /**
     * Returns historical price for a round id.
     * roundId is NOT incremental. Not all roundIds are valid.
     * You must know a valid roundId before consuming historical data.
     *
     * ROUNDID VALUES:
     *    InValid:      18446744073709562300
     *    Valid:        18446744073709562301
     *    
     * @dev A timestamp with zero value means the round is not complete and should not be used.
     */
    
     /* In situation where Chainlink only offers a ratio pair, e.g. LUNA/ETH, we use HistoricalPriceConsumerV3_RATIO, which exposes the same API but also routes */
     AggregatorV3Interface ratioQuote;
    
     constructor(address baseRatioAggregator) {
        ratioQuote = AggregatorV3Interface(baseRatioAggregator);
    }
     
    function getQuotePrice() public view returns (int256) {
      (
            , 
            int price,
            ,
            uint timeStamp,
        ) = ratioQuote.latestRoundData();
        require(timeStamp != 0, "RATIO_ORACLE_NOT_READY");
        return price;   
    }
        
    function getQuoteMantissa() internal view returns (int256) {
      return int256(10 ** ratioQuote.decimals());
    }
    
    // This returns RATIO in TERMS of QUOTE!
    function getHistoricalPrice(AggregatorV3Interface priceFeed, uint80 roundId) public view returns (int256) {
        (
            , 
            int price,
            ,
            uint timeStamp,
        ) = priceFeed.getRoundData(roundId);
        require(timeStamp > 0, "Round not complete");
        return price;
    }

    // This returns PRICE in TERMS of QUOTE!
    function getLatestPrice(AggregatorV3Interface priceFeed) public view returns (int) {
        (
            , 
            int price,
            ,
            uint timeStamp,
        ) = priceFeed.latestRoundData();
        require(timeStamp != 0, "PRICEFEED_TIMESTAMP_NOT_READY");
        return (10 ** 8) * price * getQuotePrice() / getQuoteMantissa() / int256(10 ** priceFeed.decimals());
    }
    
    function findPriceAfterTimestamp(AggregatorV3Interface priceFeed, uint timeStamp) public view returns (int256) {
        uint80 end = uint80(priceFeed.latestRound()) % (priceFeed.phaseId() * 2 ** 64);
        uint80 phaseOffset = priceFeed.phaseId() * 2 ** 64;        
        uint80 roundID = findBlockSamePhase(priceFeed, timeStamp, phaseOffset, 1, (end + 1) / 2, end );
        return getHistoricalPrice(priceFeed, roundID);
    }
    
    // Standard interface
    function getPriceAfterTimestamp(AggregatorV3Interface priceFeed, uint timeStamp) public view returns (int256) {
       return (10 ** 8) * findPriceAfterTimestamp(priceFeed, timeStamp) * findPriceAfterTimestamp(ratioQuote, timeStamp) / getQuoteMantissa() / int256(10 ** priceFeed.decimals());
    }

    /*
      Binary search within current phase
      
      Failure modes:
      1. Block wanted is at start of new phase
      2. Too many incomplete rounds 
    */
    function findBlockSamePhase(AggregatorV3Interface priceFeed, uint timeStamp, uint80 phaseOffset, uint80 start, uint80 mid, uint80 end) public view returns (uint80) {    
        require(end >= mid + 1, "Block not found");

        ( , , , uint timeStamp_2, ) = priceFeed.getRoundData(mid + phaseOffset);
        ( , , , uint timeStamp_3, ) = priceFeed.getRoundData(end + phaseOffset);
        if (timeStamp_2 == 0) return findBlockSamePhase(priceFeed, timeStamp, phaseOffset, start, mid + 1, end);
        if (timeStamp_3 == 0) return findBlockSamePhase(priceFeed, timeStamp, phaseOffset, start, mid, end - 1);

        if (end == mid + 1) {
          if ((timeStamp_3 >= timeStamp) && ( timeStamp_2 < timeStamp )) {
            return phaseOffset + end;
          }            
        }
        
        require(timeStamp_3 >= timeStamp, "Block not found");                
        require(end > start             , "Block not found");                
        if (timeStamp_2 >= timeStamp) return findBlockSamePhase(priceFeed, timeStamp, phaseOffset, start, (start+mid) / 2, mid); 
        else                          return findBlockSamePhase(priceFeed, timeStamp, phaseOffset, mid,   (mid + end) / 2, end);            
    }
    
    // Chainlink returns 8 decimal place, this normalises it to 1e6 convention in this contract
    // Note: Chainlink prices are signed

    function getLatestPriceX1e6(AggregatorV3Interface priceFeed) public view returns (int) {
      return getLatestPrice(priceFeed) / 1e2;
    }
}

// For tokens without chainlink, this would act as temporary stand-in until there's a onchain pricefeed
// Each asset type will own price set by a oracle
// All functions will ignore address provided in call, since price feed address is not available yet
 
contract HistoricalPriceConsumerV3_FIXEDPRICE {

    int     public priceX1e6;
    uint    public priceTime;
    address public ORACLE;

    constructor() {
        ORACLE = msg.sender;
    }

    function setPrice(int _price) external {
        require(ORACLE == msg.sender, "NOT ORACLE");
        priceX1e6 = _price;
        priceTime = block.timestamp;
    }
    
    function setOracle(address _oracle) external {
        require(ORACLE == msg.sender, "NOT ORACLE");
        ORACLE = _oracle;
    }

    function getLatestPrice(address priceFeed) public view returns (int) {
        return priceX1e6;
    }
    
    function getPriceAfterTimestamp(address priceFeed, uint timeStamp) public view returns (int256) {
        if (timeStamp >= priceTime) return priceX1e6;  
        revert("Block not found"); 
    }

    // Chainlink returns 8 decimal place, this temporary oracle stores it as 1e6
    // Note: Chainlink prices are signed int
    function getLatestPriceX1e6(address priceFeed) public view returns (int) {
      return priceX1e6;
    }
}