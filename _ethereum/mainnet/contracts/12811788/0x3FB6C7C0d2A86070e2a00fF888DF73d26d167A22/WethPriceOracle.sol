/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity 0.5.7;
pragma experimental ABIEncoderV2;

import "./IPriceOracle.sol";
import "./Monetary.sol";
import "./AggregatorV3Interface.sol";


/**
 * @title WethPriceOracle
 *
 * PriceOracle that returns the price of Wei in USD
 */
contract WethPriceOracle is
    IPriceOracle
{
    // ============ Storage ============
    AggregatorV3Interface public priceFeed;
    
    uint256 constant MULTIPIER_DECIMALS = 10;

    // ============ Constructor =============

    constructor(
        address _priceFeed
    )
        public
    {
        priceFeed =  AggregatorV3Interface(_priceFeed);
    }

    // ============ IPriceOracle Functions =============

    function getPrice(
        address /* token */
    )
        public
        view
        returns (Monetary.Price memory)
    {
        (
            ,
            int price,
            ,
            ,
        ) = priceFeed.latestRoundData();

        uint256 finalPrice = uint256(price) * (10 ** MULTIPIER_DECIMALS);

        return Monetary.Price({ value: uint256(finalPrice) });
    }
}
