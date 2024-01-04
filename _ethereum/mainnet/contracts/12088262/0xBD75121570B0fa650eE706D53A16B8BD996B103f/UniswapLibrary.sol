//SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "./SafeMath.sol";
import "./IUniswapV2Pair.sol";

/// Created as a separate unit because the `uniswap` lib has conflicting imports of `SafeMath` with `openzeppelin`
library UniswapLibrary {
    using SafeMath for uint256;

    /// Calculates the CREATE2 address for a pair without making any external calls
    /// @param factory Uniswap factory address
    /// @param tokenA One token in the pair
    /// @param tokenB The other token in the pair
    /// @return pair Address of the Uniswap pair
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
                    )
                )
            )
        );
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    /// @param tokenA The address of tokenA
    /// @param tokenB The address of tokenB
    /// @return token0 token1 Sorted asc addresses of tokens
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    /// Given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    /// @param amountA The amount of tokenA
    /// @param reserveA The reserver of token A
    /// @param reserveB The reserver of token B
    /// @return amountB Equivalent amount of token B
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        amountB = amountA.mul(reserveB) / reserveA;
    }

    /// Fetches and sorts the reserves for a pair
    /// @param factory Uniswap factory address
    /// @param tokenA One token in the pair
    /// @param tokenB The other token in the pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) =
            IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }
}
