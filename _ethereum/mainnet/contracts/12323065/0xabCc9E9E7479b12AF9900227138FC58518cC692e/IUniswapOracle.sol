// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IUniswapOracle {
	function getPair() external view returns (address);
	function update() external;
	function getTimeElapsed(address tokenIn, address tokenOut) external view returns (uint);
    function consultAB(uint amountIn) external view  returns (uint amountOut);
    function consultBA(uint amountIn) external view  returns (uint amountOut);
}