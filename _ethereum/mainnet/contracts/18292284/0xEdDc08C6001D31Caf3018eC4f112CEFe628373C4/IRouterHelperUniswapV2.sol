// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IRouterHelperUniswapV2 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}