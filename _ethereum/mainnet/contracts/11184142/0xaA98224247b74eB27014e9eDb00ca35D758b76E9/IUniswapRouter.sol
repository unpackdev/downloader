// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

interface IUniswapRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}