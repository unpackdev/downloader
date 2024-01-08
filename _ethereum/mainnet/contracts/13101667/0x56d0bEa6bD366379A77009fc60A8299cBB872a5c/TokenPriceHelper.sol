//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IERC20.sol";

contract TokenPriceHelper { 
    address weth9;
    address dai;
    IUniswapV2Factory factory;

    constructor(address _weth9, address _dai, address _factory) {
        weth9 = _weth9;
        dai = _dai;
        factory = IUniswapV2Factory(_factory);
    }

    function price(address token) public view returns (uint) {
        uint ethPrice = 0;
        IUniswapV2Pair ethPair = IUniswapV2Pair(factory.getPair(weth9, dai));
        (uint balance0, uint balance1,) = ethPair.getReserves();
        if (ethPair.token0() == weth9) {
            ethPrice = balance1 / balance0;
        } else {
            ethPrice = balance0 / balance1;
        }

        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(weth9, token));
        if (address(pair) == address(0)) {
            return 0;
        }

        (balance0, balance1,) = pair.getReserves();
        if (pair.token0() == weth9) {
            return balance1 * ethPrice / balance0;
        } else {
            return balance0 * ethPrice / balance1;
        }
    }
}
