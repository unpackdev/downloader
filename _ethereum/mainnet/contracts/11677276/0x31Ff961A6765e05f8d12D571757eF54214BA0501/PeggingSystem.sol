/*
    Copyright 2020 VTD team, based on the works of Dynamic Dollar Devs and Empty Set Squad

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

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Require.sol";
import "./Constants.sol";
import "./Setters.sol";

contract PeggingSystem is Setters{
    using SafeMath for uint256;
    using Decimal for Decimal.D256;

    function updateLiquidityForAllPools() public view returns (Decimal.D256 memory, Decimal.D256 memory, Decimal.D256 memory, Decimal.D256 memory, Decimal.D256 memory) {
        uint256 dsdLiquidity = Constants.getDsdOracle().getLastVtdReserve();
        uint256 usdtLiquidity = Constants.getUsdtOracle().getLastVtdReserve();
        uint256 ethLiquidity = Constants.getEthOracle().getLastVtdReserve();       
        uint256 wbtcLiquidity = Constants.getWbtcOracle().getLastVtdReserve(); 
        uint256 usdcLiquidity = Constants.getUsdcOracle().getLastVtdReserve(); 
        // uses VTD portion of the portfolio as the decimal precision is the same

        if (epoch() < Constants.getWbtcStart()) {
            wbtcLiquidity = 0;
        }

        if (epoch() < Constants.getUsdtStart()) {
            usdtLiquidity = 0;
        }

        if (epoch() < Constants.getUsdcStart()) {
            usdcLiquidity = 0;
        }

        uint256 totalLiquidity = dsdLiquidity.add(usdtLiquidity).add(ethLiquidity).add(wbtcLiquidity).add(usdcLiquidity);
        if (totalLiquidity == 0) {
            totalLiquidity = 1; //prevent division by zero
        }

        return (Decimal.ratio(dsdLiquidity, totalLiquidity), Decimal.ratio(usdtLiquidity, totalLiquidity), Decimal.ratio(ethLiquidity, totalLiquidity), Decimal.ratio(wbtcLiquidity, totalLiquidity), Decimal.ratio(usdcLiquidity, totalLiquidity));
    }

    function peggingSystemStep() internal returns (Decimal.D256 memory, bool) {
        (Decimal.D256 memory dsdPrice, bool dsdValid) = Constants.getDsdOracle().capture();
        (Decimal.D256 memory usdtPrice, bool usdtValid) = Constants.getUsdtOracle().capture();
        (Decimal.D256 memory ethPrice, bool ethValid) = Constants.getEthOracle().capture();
        (Decimal.D256 memory wbtcPrice, bool wbtcValid) = Constants.getWbtcOracle().capture();
        (Decimal.D256 memory usdcPrice, bool usdcValid) = Constants.getUsdcOracle().capture();

        return oracle().getLastPrice();
    }    
}

