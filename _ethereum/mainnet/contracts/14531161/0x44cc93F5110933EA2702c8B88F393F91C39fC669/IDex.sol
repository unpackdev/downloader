// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

/// @title Common interface for AMMs
/// @author Cosmin Grigore (@gcosmintech)
interface IDex {
    event AllowManager(address indexed owner);
    event AllowEveryone(address indexed owner);
    event ManagerChanged(
        address indexed owner,
        address indexed oldManager,
        address indexed newManager
    );
    event RouterChanged(
        address indexed owner,
        address indexed oldRouter,
        address indexed newRouter
    );
    event FactoryChanged(
        address indexed owner,
        address indexed oldFactory,
        address indexed newFactory
    );
    event Swapped(
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 _amountIn,
        uint256 _amountOut
    );
    event AddedLiquidity(
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 usedA,
        uint256 usedB,
        uint256 obtainedLP
    );

    event RemovedLiquidity(
        address indexed tokenA,
        address indexed tokenB,
        uint256 liquidity,
        uint256 obtainedA,
        uint256 obtainedB
    );

    function getAmountsOut(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        bytes calldata _data
    ) external payable returns (uint256);

    function swap(
        address _tokenA,
        address _tokenB,
        bytes calldata _amountsData,
        bytes calldata _data
    ) external returns (uint256);

    function addLiquidity(
        address _tokenA,
        address _tokenB,
        address _recipient,
        bytes calldata _amountsData,
        bytes calldata _data
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function removeLiquidity(
        address _tokenA,
        address _tokenB,
        address _recipient,
        bytes calldata _amountsData,
        bytes calldata _data
    ) external returns (uint256, uint256);
}
