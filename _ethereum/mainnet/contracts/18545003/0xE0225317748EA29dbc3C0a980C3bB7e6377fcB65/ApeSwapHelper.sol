// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

import "./IUniswapV3Pool.sol";
import "./PoolAddress.sol";

library ApeSwapHelper {
    /**
     * @notice Calculates the amount required from desired amount after fees are taken out.
     * @param amount The desired amount.
     * @param fee The fee to take out.
     * @return The amount required after fees are taken out.
     */
    function calcAmountBeforeFees(
        uint256 amount,
        uint256 fee
    ) internal pure returns (uint256) {
        return (amount * 10_000) / (10_000 - fee);
    }

    struct PoolInfo {
        address buyToken;
        address sellToken;
        uint24 fee;
    }

    /**
     * @notice Calculates the pool key for a given pool.
     * @param _poolInfo The pool info.
     * @return The pool key.
     */
    function getPoolKey(
        PoolInfo memory _poolInfo
    ) internal pure returns (PoolAddress.PoolKey memory) {
        return
            PoolAddress.getPoolKey(
                _poolInfo.buyToken,
                _poolInfo.sellToken,
                _poolInfo.fee
            );
    }

    /**
     * @notice Computes the pool address for a given pool info.
     * @param factory The factory address.
     * @param _poolInfo The pool info.
     * @return The pool.
     */
    function getPool(
        address factory,
        PoolInfo memory _poolInfo
    ) internal pure returns (IUniswapV3Pool) {
        return getPool(factory, getPoolKey(_poolInfo));
    }

    /**
     * @notice Computes the pool address for a given pool key.
     * @param factory The factory address.
     * @param _poolKey The pool key.
     * @return The pool.
     */
    function getPool(
        address factory,
        PoolAddress.PoolKey memory _poolKey
    ) internal pure returns (IUniswapV3Pool) {
        return IUniswapV3Pool(PoolAddress.computeAddress(factory, _poolKey));
    }
}
