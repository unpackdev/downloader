// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.20;

import "./IUniswapV3Pool.sol";
import "./PoolAddress.sol";
import "./ToadStructs.sol";
/// @notice Provides validation for callbacks from Uniswap V3 Pools
library CallbackValidation {
    /// @notice Returns the address of a valid Uniswap V3 Pool
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param dex The dex that represents the V3 factory and initcode
    /// @return pool The V3 pool contract address
    function verifyCallback(
        address tokenA,
        address tokenB,
        uint24 fee,
        ToadStructs.DexData memory dex
    ) internal view returns (IUniswapV3Pool pool) {
        return verifyCallback(PoolAddress.getPoolKey(tokenA, tokenB, fee), dex);
    }

    /// @notice Returns the address of a valid Uniswap V3 Pool
    /// @param poolKey The identifying key of the V3 pool
    /// @return pool The V3 pool contract address
    function verifyCallback( PoolAddress.PoolKey memory poolKey, ToadStructs.DexData memory dex)
        internal
        view
        returns (IUniswapV3Pool pool)
    {
        pool = IUniswapV3Pool(PoolAddress.computeAddress(dex.factory, dex.initcode, poolKey));
        require(msg.sender == address(pool));
    }
}
