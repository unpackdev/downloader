// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import "./ConditionalTokens.sol";
import "./SafeMath.sol";



///@dev interface to read price oracles
interface IMakerPriceFeed {
  function read() external view returns (bytes32);
}
//kovan ConditionalTokens Address 0xf09F9DD23147E5B4139545Bc9ECf282922ec0a1D

contract MakerAdapter {
     using SafeMath for uint256;
     ConditionalTokens public immutable cTokens;
      
      
    /// Mapping key is a questionId. Value is struct containing market values
    mapping(bytes32 => Market) public markets;
     struct  Market {
        address makerPriceFeed;
        uint resolutionTime;
        uint targetValue;
        uint variation;
    }
    

    /// @dev Emitted upon the successful reporting of whether the actual value has exceeded target to the conditional tokens contract.
 
    event ResolutionSuccessful(bytes32 questionId, uint resolutionTime, uint currentTime, uint value, uint[] result);
    
    ///@dev Emitted upon market preparation
  
    event MarketPrepared(bytes32 questionId, uint resolutionTime, uint targetValue, uint variation);
    
   
    
    /// @param _cTokens address of conditional tokens contract to be used
    constructor (ConditionalTokens _cTokens) public {
        cTokens = _cTokens;
    
       
    }
 
    ///@dev Function defines values to be used for market resolution.
    ///@param questionId  bytes32 identifier for the question to be resolved
    ///@param makerPriceFeed address of token price oracle.
    
    ///@param resolutionTime timestamp of start of valid market resolution window
    ///@param targetValue predicted token price
    ///@param variation  To define a binary market set to 0. To define a scalar market set to desired plus and minus range. Bounds are equal to targetValue +- variation.
  function prepareMarket(bytes32 questionId,  address makerPriceFeed, uint resolutionTime, uint targetValue, uint variation)  external {
      require(resolutionTime >= block.timestamp,  "Please submit a resolution time in the future");
      cTokens.prepareCondition(address(this), questionId, 2);
      markets[questionId].makerPriceFeed = makerPriceFeed;
      markets[questionId].resolutionTime = resolutionTime;
      markets[questionId].targetValue = targetValue;
      markets[questionId].variation = variation;
      
      
      
       emit MarketPrepared(questionId, resolutionTime, targetValue, variation);
  }
   ///@dev reads the price of the token
   ///@param makerPriceFeed address of relevant Maker DAO price feed. Defined at market preparation. 
   
  function getPrice(address makerPriceFeed) internal view returns (uint) {
    
       return uint(IMakerPriceFeed(makerPriceFeed).read());
    
  }
    ///@dev resolves market by getting price from feed, comparing to target value and calling Conditional Tokens reportPayouts function with an array of uints representing payout numerators.
    ///@param questionId used in market preparation
  
    function resolveMarket(bytes32 questionId) external {
      require(markets[questionId].resolutionTime <= block.timestamp, "resolution window has not begun");
     
      
        ///@param value oracle's response
        uint value = getPrice(markets[questionId].makerPriceFeed);
        uint lowerBound = markets[questionId].targetValue.sub(markets[questionId].variation);
        uint upperBound =  markets[questionId].targetValue.add(markets[questionId].variation);
        uint hundred = 100;
        uint[] memory result = new uint[](2);
        /// if value is lower than lower bound pays 100% to short position and 0 to long.
        if (value < lowerBound) {
              result[0] = 1;
              result[1] = 0;
          cTokens.reportPayouts(questionId, result);
        } 
        /// if value is higher than higher bound pays 100% to long position and 0 to short.
        else if (value > upperBound) {
             result[0] = 0;
             result[1] = 1;
         cTokens.reportPayouts(questionId, result);
        } 
        /// Finds where in the range defined by upper and lower bounds the price value falls and determines proportional payouts.
          else  {
            uint ratio = value.sub(lowerBound).mul(hundred);
            uint range = upperBound.sub(lowerBound);
            uint longPayout = ratio.div(range);
            result[0] = hundred.sub(longPayout);
            result[1] = longPayout;
        cTokens.reportPayouts(questionId, result);
        }
        
        emit ResolutionSuccessful(questionId, markets[questionId].resolutionTime, block.timestamp, value, result);

    }
  
}