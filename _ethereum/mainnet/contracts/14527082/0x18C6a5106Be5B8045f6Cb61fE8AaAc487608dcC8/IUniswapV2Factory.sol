interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}