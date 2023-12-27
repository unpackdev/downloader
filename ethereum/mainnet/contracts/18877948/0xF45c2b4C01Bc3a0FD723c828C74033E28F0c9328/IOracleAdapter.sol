// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;


interface IOracleAdapter  {

    
    function getAmountOut(
        uint amountIn, 
        address[] memory path
    ) external view returns (uint256 amountOut);

    function getAmountIn(uint amountOut, address[] memory path)
        external
        view
        returns (uint256 amountIn);

}