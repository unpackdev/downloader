// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAipPool.sol";
import "./PoolAddress.sol";

library CallbackValidation {
    function verifyCallback(
        address factory,
        address token0,
        address token1,
        uint8 frequency
    ) internal view returns (IAipPool pool) {
        return
            verifyCallback(
                factory,
                PoolAddress.getPoolInfo(token0, token1, frequency)
            );
    }

    function verifyCallback(
        address factory,
        PoolAddress.PoolInfo memory poolInfo
    ) internal view returns (IAipPool pool) {
        pool = IAipPool(PoolAddress.computeAddress(factory, poolInfo));
        require(msg.sender == address(pool));
    }
}
