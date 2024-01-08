
// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Ownable.sol";
import "./IPriceFeed.sol";
import "./SafeDecimalMath.sol";
import "./SafeMath.sol";
import "./AggregatorV3Interface.sol";

contract PriceFeed is Ownable, IPriceFeed {
    uint80 private mRoundId;
    int256 private  mAnswer;
    uint256 private  mStartedAt; 
    uint256 private  mUpdatedAt;
    uint80 private  mAnsweredInRound;
    bool private mPriceError;

    function setRoundData( uint80 roundId, 
            int256 answer, 
            uint256 startedAt, 
            uint256 updatedAt, 
            uint80 answeredInRound ) public onlyOwner {

        mRoundId = roundId;
        mAnswer = answer;
        mStartedAt = startedAt; 
        mUpdatedAt = updatedAt;
        mAnsweredInRound = answeredInRound;
        mPriceError = false;
    }

    function latestRoundData() override external view 
        returns (
            uint80 roundId, 
            int256 answer, 
            uint256 startedAt, 
            uint256 updatedAt, 
            uint80 answeredInRound
        ){
        roundId = mRoundId;
        answer = mAnswer;
        startedAt = mStartedAt; 
        updatedAt = mUpdatedAt;
        answeredInRound = mAnsweredInRound;
    }

    function setPriceError( bool bError ) public onlyOwner {
        mPriceError = bError;
    }

    function checkPriceError() external view override returns ( bool error ){
        return mPriceError;
    }     

}

contract ChickPriceFeed is PriceFeed {

}


contract ChainlinkEurEthPriceFeed is Ownable, IPriceFeed {
    using SafeDecimalMath for uint;
    using SafeMath for uint;

    AggregatorV3Interface public mEthUsdPrice;
    AggregatorV3Interface public mEurUsdPrice;

    constructor( AggregatorV3Interface ethPriceFeed, AggregatorV3Interface eurPriceFeed ) public {
        mEthUsdPrice = ethPriceFeed;
        mEurUsdPrice = eurPriceFeed;
    }

    function setPriceFeed( AggregatorV3Interface ethPriceFeed, AggregatorV3Interface eurPriceFeed ) public onlyOwner {
        mEthUsdPrice = ethPriceFeed;
        mEurUsdPrice = eurPriceFeed;
    }

    function latestRoundData() override external view 
        returns (
            uint80 roundId, 
            int256 answer, 
            uint256 startedAt, 
            uint256 updatedAt, 
            uint80 answeredInRound
        ){
        int256 ethAnswer;
        int256 eurAnswer;            
        ( roundId, ethAnswer, startedAt, updatedAt, answeredInRound ) = mEthUsdPrice.latestRoundData();
        ( , eurAnswer, , , ) = mEurUsdPrice.latestRoundData();
        if( ethAnswer > 0 && eurAnswer > 0 ){
            // chainlink is 8 precise
            uint256 uEthPrice = uint256(ethAnswer).mul(100000000);
            uint256 uEurPrice = uint256(eurAnswer).mul(100000000);

            answer = int256(uEthPrice.divideDecimal( uEurPrice));
        }
    }

    function setPriceError( bool bError ) public onlyOwner {
    }

    function checkPriceError() external view override returns ( bool error ){
        return false;
    }     

}

