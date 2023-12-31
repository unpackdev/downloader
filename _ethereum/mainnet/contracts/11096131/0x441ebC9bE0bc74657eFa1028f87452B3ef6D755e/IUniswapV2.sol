// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

interface IUniswapV2 {
    function swapExactTokensForTokens(
        uint256,
        uint256,
        address[] calldata,
        address,
        uint256
    ) external;
}
