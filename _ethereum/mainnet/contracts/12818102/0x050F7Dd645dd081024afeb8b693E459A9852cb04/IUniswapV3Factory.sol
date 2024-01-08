// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./IERC20.sol";
import "./IUniswapV3Pool.sol";


interface IUniswapV3Factory {
    function getPool(IERC20 tokenA, IERC20 tokenB, uint24 fee) external view returns (IUniswapV3Pool pool);
}
