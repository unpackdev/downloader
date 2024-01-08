// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.7.6;

import "./IUniswapV2Pair.sol";

import "./SafeMath.sol";

// Forked from https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol
// Modified getReserves() to accept a pair rather than factory and updates to the internal SafeMath that's not pegged to solc 0.6.6
// Sushiswap's factory uses a different init code than UniswapV2's, and so it's more reliable to
// grab the pair's address from the factory than to calculate it
library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address pair, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pair).getReserves();
        (address token0,) = sortTokens(tokenA, tokenB);
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }
}
