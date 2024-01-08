// contracts/membership/connectors/UniswapV2Connector.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import {IUniswapRouter}from "../../interfaces/dex/IUniswapRouter.sol";

contract DexAMM {
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    uint256 public constant deadline = 0xf000000000000000000000000000000000000000000000000000000000000000;

    function _getPathFromTokenToToken(address fromToken, address toToken) internal pure returns (address[] memory) {
		if (fromToken == WETH || toToken == WETH) {
			address[] memory path = new address[](2);
			path[0] = fromToken == WETH ? WETH : fromToken;
			path[1] = toToken == WETH ? WETH : toToken;
			return path;
		} else {
			address[] memory path = new address[](3);
			path[0] = fromToken;
			path[1] = WETH;
			path[2] = toToken;
			return path;
		}
	}

    function estimateSwapAmount(
		address _fromToken,
		address _toToken,
		uint256 _amountOut
	) public view returns (uint256) {
		uint256[] memory amounts;
		address[] memory path;
		path = _getPathFromTokenToToken(_fromToken, _toToken);
		amounts = IUniswapRouter(uniswapRouter).getAmountsIn(_amountOut, path);
		return amounts[0];
	}

	function _swapTokenForToken(
		address _tokenIn,
		address _tokenOut,
		uint256 _amount, 
		uint256 _amountOutMin
	) internal returns (uint256) {
		address[] memory path = _getPathFromTokenToToken(_tokenIn, _tokenOut);
		uint256[] memory amounts = IUniswapRouter(uniswapRouter).swapExactTokensForTokens(_amount, _amountOutMin, path, address(this), deadline);
		return amounts[path.length - 1];
	}

	function _swapETHForToken(address _tokenOut, uint256 _amountIn, uint256 _amountOutMin) internal returns (uint256) {
		address[] memory path = _getPathFromTokenToToken(WETH, _tokenOut);
		uint256[] memory amounts = IUniswapRouter(uniswapRouter).swapExactETHForTokens{ value: _amountIn }(_amountOutMin, path, address(this), deadline); // amounts[0] = WETH, amounts[end] = tokens
		return amounts[path.length - 1];
	}
}
