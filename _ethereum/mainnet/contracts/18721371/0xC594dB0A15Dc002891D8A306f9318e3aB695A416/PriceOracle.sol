// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./AggregatorV3Interface.sol";
import "./Withdrawable.sol";
import "./PriceOracleInterface.sol";


contract PriceOracle is Ownable, Withdrawable, PriceOracleInterface {

    uint256 private baseQuote;
    uint256 private baseQuoteDecimals;
    uint16 private baseQuoteDevianceMax;    
    uint32 private quoteMaxAgeInSeconds;
    uint8 private oracleDecimals;
    
    address private externalOracle;

    event MaxAgeConfigurationChanged(uint32 ageinseconds);
    event MaxDevianceConfigurationChanged(uint16 percentile);
    event BaseQuoteConfigurationChanged(uint256 quote, uint256 decimals);
    event ExternalOracleConfigurationChanged(address externaloracleaddress);

    function SetQuoteMaxAge(uint32 ageInSeconds) public onlyOwner {
      require(ageInSeconds != 0, "Quote age cannot be zero");
      quoteMaxAgeInSeconds = ageInSeconds;
      emit MaxAgeConfigurationChanged(ageInSeconds);
    }

    function SetMaximumBaseQuoteDeviance(uint16 percentile) public onlyOwner {

      require(percentile != 0, "Quote deviance cannot be zero");      
      baseQuoteDevianceMax = percentile;

      emit MaxDevianceConfigurationChanged(percentile);
    }

    function SetBaseQuote(uint256 quote, uint256 decimals) public onlyOwner {

      require(quote != 0, "Quote value cannot be zero");
      require(decimals != 0, "Quote decimals cannot be zero");
      baseQuote = quote;
      baseQuoteDecimals = decimals;
      emit BaseQuoteConfigurationChanged(quote, decimals);
    }

    function SetExternalOracle(address externalOracleAddress) public onlyOwner
    {
        externalOracle = externalOracleAddress;
        AggregatorV3Interface oracle = AggregatorV3Interface(externalOracle);
        oracleDecimals = oracle.decimals();
        emit ExternalOracleConfigurationChanged(externalOracleAddress);
    }

    function getQuoteFromExternalOracle() private view returns(PriceOracleStructures.PriceOracleData memory) {
      
      require(externalOracle != address(0));
      PriceOracleStructures.PriceOracleData memory result;

      AggregatorV3Interface oracle = AggregatorV3Interface(externalOracle);

      (result.roundId,
      result.answer,
      result.startedAt,
      result.updatedAt,
      result.answeredInRound) = oracle.latestRoundData();

      result.decimals = oracleDecimals;

      return result;

    }

    function getQuote() view public returns(PriceOracleStructures.PriceOracleData memory)
    {
      return getQuoteFromExternalOracle();
    }

    function IsQuoteTooOld(PriceOracleStructures.PriceOracleData memory quote) view public returns(bool) 
    {      
      return false;
     // require(quoteMaxAgeInSeconds != 0, "Quote age configuation not set, cannot determine if its too old");
      //require(quote.decimals == baseQuoteDecimals, "Decimals of base quote do not match quote of oracle");           
    }

    function IsQuoteTooDeviant(PriceOracleStructures.PriceOracleData memory quote) view public returns(bool) 
    {      
      return false;
      //require(baseQuote !=0, "Base quote not set cannot determine if its deviant");
      //require(baseQuoteDevianceMax != 0, "Deviance tolerance not set, cannot determine if its deviant");
      //require(quote.decimals == baseQuoteDecimals, "Decimals of base quote do not match quote of oracle");      
    }

}
