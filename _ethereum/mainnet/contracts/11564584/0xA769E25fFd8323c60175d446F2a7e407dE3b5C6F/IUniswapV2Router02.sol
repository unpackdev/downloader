pragma solidity >=0.6.2;

interface IUniswapV2Router02 {
    function WETH() external view returns (address);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
}