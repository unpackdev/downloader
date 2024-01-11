//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./IExchangeRateFeeder.sol";

interface IConversionPool {
    function deposit(uint256 _amount, uint256 _minAmountOut) external;
    function redeem(uint256 _amount) external;
    function inputToken() external view returns (IERC20);
    function outputToken() external view returns (IERC20);
    function proxyInputToken() external view returns (IERC20);
    function feeder() external view returns (IExchangeRateFeeder);
}