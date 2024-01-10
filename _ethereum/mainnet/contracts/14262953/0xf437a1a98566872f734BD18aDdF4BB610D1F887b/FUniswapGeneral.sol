// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

import "./IUniswapV2Router02.sol";

function _getAmountOut(
    uint256 _amountIn,
    address[] memory _path,
    address _uniRouter
) view returns (uint256 amountOut) {
    uint256[] memory amountsOut = IUniswapV2Router02(_uniRouter).getAmountsOut(
        _amountIn,
        _path
    );
    amountOut = amountsOut[amountsOut.length - 1];
}

function _getAmountIn(
    uint256 _amountOut,
    address[] memory _path,
    address _uniRouter
) view returns (uint256 amountIn) {
    uint256[] memory amountsIn = IUniswapV2Router02(_uniRouter).getAmountsIn(
        _amountOut,
        _path
    );
    amountIn = amountsIn[0];
}
