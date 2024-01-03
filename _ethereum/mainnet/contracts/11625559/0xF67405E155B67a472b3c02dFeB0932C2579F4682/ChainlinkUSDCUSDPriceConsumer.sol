// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./AggregatorV3Interface.sol";
import "./SignedSafeMath.sol";

contract ChainlinkUSDCUSDPriceConsumer {
    using SignedSafeMath for int256;

    AggregatorV3Interface internal priceFeedUSDCETH;
    AggregatorV3Interface internal priceFeedETHUSD;


    constructor() public {
        // mainnet
        priceFeedUSDCETH = AggregatorV3Interface(0x986b5E1e1755e3C2440e960477f25201B0a8bbD4); // usdc-eth.data.eth
        priceFeedETHUSD  = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419); // eth-usd.data.eth

    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (
            , 
            int256 priceUSDCETH,
            ,
            ,
            
        ) = priceFeedUSDCETH.latestRoundData(); // 835781130862914, 18    


        (
            , 
            int256 priceETHUSD,
            ,
            ,
            
        ) = priceFeedETHUSD.latestRoundData(); // 119804000000, 8 
        
        

        int price = priceUSDCETH.mul(priceETHUSD).div(int256(10) ** priceFeedUSDCETH.decimals());


        return price;
    }

    function getDecimals() public view returns (uint8) {
        return priceFeedETHUSD.decimals();  //8
    }
    
    
}

