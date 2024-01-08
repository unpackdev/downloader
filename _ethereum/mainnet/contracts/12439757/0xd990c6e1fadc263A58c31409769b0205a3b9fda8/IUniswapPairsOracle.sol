pragma solidity =0.6.6;

interface IUniswapPairsOracle {
    function addPair(address tokenA, address tokenB) external returns (bool);

    function pairFor(address tokenA, address tokenB) external view returns(address);

    function update(address pair) external returns (bool);

    function consult(address pair, address token, uint256 amountIn)
        external
        view
        returns (uint256 amountOut);
    
}
