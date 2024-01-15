// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "./IERC20.sol";
import "./IUniswapExchange.sol";

interface IUniswapFactory {
    function getPair(IERC20 tokenA, IERC20 tokenB) external view returns (IUniswapExchange pair);
}
