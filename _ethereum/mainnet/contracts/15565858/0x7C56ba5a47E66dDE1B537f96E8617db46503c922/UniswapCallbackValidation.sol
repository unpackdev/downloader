// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IUniswapV3Pool.sol";
import "./UniswapPoolAddress.sol";

/// @notice Provides validation for callbacks from Uniswap V3 Pools
library UniswapCallbackValidation {
    /// @notice Returns the address of a valid Uniswap V3 Pool
    /// @param factory The contract address of the Uniswap V3 factory
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The V3 pool contract address
    function verifyCallback(
        address factory,
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal view returns (IUniswapV3Pool pool) {
        return
            verifyCallback(
                factory,
                UniswapPoolAddress.getPoolKey(tokenA, tokenB, fee)
            );
    }

    /// @notice Returns the address of a valid Uniswap V3 Pool
    /// @param factory The contract address of the Uniswap V3 factory
    /// @param poolKey The identifying key of the V3 pool
    /// @return pool The V3 pool contract address
    function verifyCallback(
        address factory,
        UniswapPoolAddress.PoolKey memory poolKey
    ) internal view returns (IUniswapV3Pool pool) {
        pool = IUniswapV3Pool(
            UniswapPoolAddress.computeAddress(factory, poolKey)
        );
        require(msg.sender == address(pool));
    }
}
