// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";

import "./Common.sol";

library UniswapV2Helper {
    /// @notice Thrown when two tokens are identical
    error IdenticalAddresses();
    /// @notice Thrown when input amount is zero
    error InsufficientAmount();
    /// @notice Thrown when there is no liquidity of the tokens
    error InsufficientLiquidity();
    /// @notice Thrown when path array length is less than two
    error InvalidPath();

    /// @dev Returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(
        address tokenA,
        address tokenB
    ) internal pure returns (address token0, address token1) {
        if (tokenA == tokenB) {
            revert IdenticalAddresses();
        }
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        if (token0 == address(0)) {
            revert ZeroAddress();
        }
    }

    /// @dev Calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        IUniswapV2Factory factory,
        address tokenA,
        address tokenB
    ) internal view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = factory.getPair(token0, token1);
    }

    /// @dev Fetches and sorts the reserves for a pair
    function getReserves(
        IUniswapV2Factory factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint112 reserveA, uint112 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        IUniswapV2Pair pair = IUniswapV2Pair(pairFor(factory, tokenA, tokenB));
        uint112 reserve0;
        uint112 reserve1;
        if (address(pair) != address(0)) {
            (reserve0, reserve1, ) = IUniswapV2Pair(pair).getReserves();
        }
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    /// @dev Given some amount of an asset and pair reserves, returns an equivalent amount of the other
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        if (amountA == 0) {
            revert InsufficientAmount();
        }
        if (reserveA == 0 && reserveB == 0) {
            revert InsufficientLiquidity();
        }
        amountB = (amountA * reserveB) / reserveA;
    }

    /// @dev Given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        if (amountIn == 0) {
            revert InsufficientAmount();
        }
        if (reserveIn == 0 && reserveOut == 0) {
            revert InsufficientLiquidity();
        }
        uint256 numerator = amountIn * reserveOut;
        uint256 denominator = reserveIn;
        amountOut = numerator / denominator;
    }

    /// @dev Performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        IUniswapV2Factory factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        if (path.length < 2) {
            revert InvalidPath();
        }
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i],
                path[i + 1]
            );
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }
}
