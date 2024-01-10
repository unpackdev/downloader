// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import "./GenerativeBB.sol";
import "./NonGenerativeBB.sol";

contract BlindBox is NonGenerativeBB {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    

     struct Series1 {
        string name;
        string seriesURI;
        string boxName;
        string boxURI;
        uint256 startTime;
        uint256 endTime;
        string collection; 
    }
    struct Series2 {
        uint256 maxBoxes;
        uint256 perBoxNftMint;
        uint256 perBoxPrice;
        address bankAddress;
        uint256 baseCurrency;
        uint256[] allowedCurrencies; 
        string name;
    }
    /** 
    @dev constructor initializing blindbox
    */
    constructor() payable  {

    }

    /** 
    @dev this function is to start new series of blindbox
    @param isGenerative flag to show either newely started series is of Generative blindbox type or Non-Generative
    @notice only owner of the contract can trigger this function.
    */
    function StartSeries(
        // address[] memory addressData, // [collection, bankAddress]
        string[] memory stringsData, // [name, seriesURI, boxName, boxURI]
       uint256[] memory integerData, //[startTime, endTime, maxBoxes, perBoxNftMint, perBoxPrice, baseCurrency]
       uint256[] memory allowedCurrencies,
        bool isGenerative,  address bankAddress, uint256 royalty, bool isWhiteListed, bool _isCryptoAlowed ) onlyOwner public {
            Series1 memory series = Series1( stringsData[0], stringsData[1], stringsData[2], stringsData[3], integerData[0], integerData[1],stringsData[4]);
        if(isGenerative){
            // start generative series
            // generativeSeriesId.increment();
            generativeSeries(stringsData[4],  stringsData[0], stringsData[1], stringsData[2], stringsData[3], integerData[0], integerData[1], royalty);
           
            // emit SeriesInputValue(series,generativeSeriesId.current(), isGenerative,  royalty);
 
        } else { 
            _isWhiteListed[nonGenerativeSeriesId.current()] = isWhiteListed;
            _perBoxUserLimit[nonGenerativeSeriesId.current()] = integerData[6];
            // _isCryptoAllowed[nonGenerativeSeriesId.current()] = _isCryptoAlowed;
            nonGenerativeSeriesId.increment();
            // start non-generative series
            nonGenerativeSeries(stringsData[4], stringsData[0], stringsData[1], stringsData[2], stringsData[3], integerData[0], integerData[1], royalty);
           
        emit SeriesInputValue(series,nonGenerativeSeriesId.current(), isGenerative, royalty, isWhiteListed );
          }
       extraPsrams(integerData, bankAddress, allowedCurrencies, isGenerative, stringsData[0]);
        
    }
    function extraPsrams(uint256[] memory integerData, //[startTime, endTime, maxBoxes, perBoxNftMint, perBoxPrice, baseCurrency]
         address bankAddress,
        uint256[] memory allowedCurrencies, bool isGenerative, string memory blindName) internal {
        if(isGenerative){
      setExtraParamsGen(integerData[5], allowedCurrencies, bankAddress, integerData[4], integerData[2], integerData[3]);  

        } else {
      setExtraParams(integerData[5], allowedCurrencies, bankAddress, integerData[4], integerData[2], integerData[3]);  

        }
        Series2 memory series = Series2(integerData[2], integerData[3], integerData[4], bankAddress, integerData[5], allowedCurrencies, blindName );
        emit Series1InputValue(series,nonGenerativeSeriesId.current(), isGenerative );
    }
    // add URIs/attributes in series [handled in respective BBs]
    function updateWhiteList(uint256 seriesId, bool isWhiteListed)onlyOwner public {
      _isWhiteListed[seriesId] = isWhiteListed;
    }
    
    fallback() payable external {}
    receive() payable external {}
  event SeriesInputValue(Series1 _series, uint256 seriesId, bool isGenerative, uint256 royalty, bool whiteListOnly);
    event Series1InputValue(Series2 _series, uint256 seriesId, bool isGenerative);
}