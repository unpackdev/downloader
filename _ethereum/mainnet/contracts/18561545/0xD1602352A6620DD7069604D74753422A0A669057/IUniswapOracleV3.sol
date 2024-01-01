// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IUniswapOracleV3 {
    function PERIOD() external returns (uint256);

    function factory() external returns (address);

    function consult(
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut
    ) external view returns (uint256 _amountOut);

    function getPool(
        address _tokenIn,
        address _tokenOut
    ) external view returns (address _pool);
}
