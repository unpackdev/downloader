// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface PriceOracleInterface
{
     function getQuote() external view returns(PriceOracleStructures.PriceOracleData memory);

     function IsQuoteTooDeviant(PriceOracleStructures.PriceOracleData memory quote) external view returns(bool) ;

     function IsQuoteTooOld(PriceOracleStructures.PriceOracleData memory quote) external view returns(bool) ;
     
}

library PriceOracleStructures
{
    struct PriceOracleData
          {
            uint8 decimals;
            uint80 roundId;
            int256 answer;
            uint256 startedAt;
            uint256 updatedAt; 
            uint80 answeredInRound;
          }
}