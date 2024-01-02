pragma solidity 0.8.19;

interface IUniswapV2Router {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
    returns (uint[] memory amounts);


    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Pool {
    function token0() external view returns (address);
    function token1() external view returns (address);
}
