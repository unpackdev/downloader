// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.7.6;

import "./Token.sol";
import "./IVault.sol";

interface IPool is IERC20 {

    function repricingBlock() external view returns(uint);

    function baseFee() external view returns(uint);
    function feeAmp() external view returns(uint);
    function maxFee() external view returns(uint);

    function pMin() external view returns(uint);
    function qMin() external view returns(uint);
    function exposureLimit() external view returns(uint);
    function volatility() external view returns(uint);

    function derivativeVault() external view returns(IVault);
    function dynamicFee() external view returns(address);
    function repricer() external view returns(address);

    function isFinalized()
    external view
    returns (bool);

    function getNumTokens()
    external view
    returns (uint);

    function getTokens()
    external view
    returns (address[] memory tokens);

    function getLeverage(address token)
    external view
    returns (uint);

    function getBalance(address token)
    external view
    returns (uint);

    function getController()
    external view
    returns (address);

    function setController(address manager)
    external;


    function joinPool(uint poolAmountOut, uint[2] calldata maxAmountsIn)
    external;

    function exitPool(uint poolAmountIn, uint[2] calldata minAmountsOut)
    external;

    function swapExactAmountIn(
        address tokenIn,
        uint tokenAmountIn,
        address tokenOut,
        uint minAmountOut
    )
    external
    returns (uint tokenAmountOut, uint spotPriceAfter);
}
