// SPDX-License-Identifier: MIT
// Copyright 2021 Primitive Finance
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity 0.6.2;

/**
 * @title   Primitive Swaps Lib
 * @author  Primitive
 * @notice  Library for calculating different proportions of long and short option tokens.
 * @dev     @primitivefi/v1-connectors@2.0.0
 */

import "./ITrader.sol";
import "./SafeMath.sol";

library CoreLib {
    using SafeMath for uint256; // Reverts on math underflows/overflows

    /**
     * @dev     Calculates the proportional quantity of long option tokens per short option token.
     * @notice  For each long option token, there is quoteValue / baseValue quantity of short option tokens.
     * @param   optionToken The Option to use to calculate proportional amounts. Each option has different proportions.
     * @param   short The amount of short options used to calculate the proportional amount of long option tokens.
     * @return  The proportional amount of long option tokens based on `short`.
     */
    function getProportionalLongOptions(IOption optionToken, uint256 short)
        internal
        view
        returns (uint256)
    {
        return short.mul(optionToken.getBaseValue()).div(optionToken.getQuoteValue());
    }

    /**
     * @dev     Calculates the proportional quantity of short option tokens per long option token.
     * @notice  For each short option token, there is baseValue / quoteValue quantity of long option tokens.
     * @param   optionToken The Option to use to calculate proportional amounts. Each option has different proportions.
     * @param   long The amount of long options used to calculate the proportional amount of short option tokens.
     * @return  The proportional amount of short option tokens based on `long`.
     */
    function getProportionalShortOptions(IOption optionToken, uint256 long)
        internal
        view
        returns (uint256)
    {
        return long.mul(optionToken.getQuoteValue()).div(optionToken.getBaseValue());
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }
}
