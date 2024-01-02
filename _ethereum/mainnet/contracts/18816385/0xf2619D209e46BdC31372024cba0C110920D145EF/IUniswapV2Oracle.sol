// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IUniswapV2Oracle {

    // performs chained update calculations on any number of pairs
    //whitelisted to avoid DDOS attacks since new pairs will be registered
    function updatePath(address[] memory path) external;

    //updates all pairs registered 
    function updateAll() external returns (uint updatedPairs) ;
    
    // performs chained getAmountOut calculations on any number of pairs
    function consultAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);

    // returns the amount out corresponding to the amount in for a given token using the moving average over the time
    // range [now - [windowSize, windowSize - periodSize * 2], now]
    // update must have been called for the bucket corresponding to timestamp `now - windowSize`
    function consult(address tokenIn, uint amountIn, address tokenOut) external view returns (uint amountOut);

}