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

import "./Num.sol";

contract Math is Bronze, Const, Num {
    /**********************************************************************************************
    // calcSpotPrice                                                                             //
    // sP = spotPrice                                                                            //
    // bI = tokenBalanceIn                 bI          1                                         //
    // bO = tokenBalanceOut         sP =  ----  *  ----------                                    //
    // sF = swapFee                        bO      ( 1 - sF )                                    //
    **********************************************************************************************/
    function calcSpotPrice(
        uint tokenBalanceIn,
        uint tokenBalanceOut,
        uint swapFee
    )
        public pure
        returns (uint spotPrice)
    {
        uint ratio = div(tokenBalanceIn, tokenBalanceOut);
        uint scale = div(BONE, sub(BONE, swapFee));
        spotPrice = mul(ratio, scale);
    }

    /**********************************************************************************************
    // calcOutGivenIn                                                                            //
    // aO = tokenAmountOut                                                                       //
    // bO = tokenBalanceOut                                                                      //
    // bI = tokenBalanceIn              /      /            bI             \   \                 //
    // aI = tokenAmountIn    aO = bO * |  1 - | --------------------------  |  |                 //
    // sF = swapFee                     \      \ ( bI + ( aI * ( 1 - sF )) /   /                 //
    **********************************************************************************************/
    function calcOutGivenIn(
        uint tokenBalanceIn,
        uint tokenBalanceOut,
        uint tokenAmountIn,
        uint swapFee
    )
        public pure
        returns (uint tokenAmountOut)
    {
        uint adjustedIn = sub(BONE, swapFee);
        adjustedIn = mul(tokenAmountIn, adjustedIn);
        uint y = div(tokenBalanceIn, add(tokenBalanceIn, adjustedIn));
        uint bar = sub(BONE, y);
        tokenAmountOut = mul(tokenBalanceOut, bar);
    }

    /**********************************************************************************************
    // calcInGivenOut                                                                            //
    // aI = tokenAmountIn                                                                        //
    // bO = tokenBalanceOut               /  /     bO      \       \                             //
    // bI = tokenBalanceIn          bI * |  | ------------  | - 1  |                             //
    // aO = tokenAmountOut    aI =        \  \ ( bO - aO ) /       /                             //
    // sF = swapFee                 --------------------------------                             //
    //                                              ( 1 - sF )                                   //
    **********************************************************************************************/
    function calcInGivenOut(
        uint tokenBalanceIn,
        uint tokenBalanceOut,
        uint tokenAmountOut,
        uint swapFee
    )
        public pure
        returns (uint tokenAmountIn)
    {
        uint diff = sub(tokenBalanceOut, tokenAmountOut);
        uint y = div(tokenBalanceOut, diff);
        uint foo = sub(y, BONE);
        tokenAmountIn = sub(BONE, swapFee);
        tokenAmountIn = div(mul(tokenBalanceIn, foo), tokenAmountIn);
    }
}
