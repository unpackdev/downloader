// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICurveRouterV1 {
    function get_dy(address[11] calldata _route, uint256[5][5] calldata _swap_params, uint256 _amount, address[5] calldata _pools) external view returns (uint256);

    function exchange(
        address[11] calldata _route,
        uint256[5][5] calldata _swap_params,
        uint256 _amount,
        uint256 _expected,
        address[5] calldata _pools,
        address _receiver
    ) external payable returns (uint256);
}

interface IUniswapV2Router02 {
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory);

    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] memory path, address to, uint deadline) external returns (uint[] memory);
}
