// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.9;

interface IUniswapV2Router02 {
    function swapExactTokensForTokens(
        uint256,
        uint256,
        address[] calldata,
        address,
        uint256
    ) external;

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata paths,
        address to,
        uint256 deadline
    ) external;
}
