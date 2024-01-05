interface IUniswapV2Pair {
    function token0() external pure returns (address);

    function token1() external pure returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );

    function totalSupply() external view returns (uint256);
}
