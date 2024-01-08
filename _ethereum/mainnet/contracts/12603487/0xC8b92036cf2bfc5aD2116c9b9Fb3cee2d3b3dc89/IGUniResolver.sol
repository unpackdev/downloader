// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;

import "./IGUniPool.sol";

interface IGUniResolver {
    function getUnderlyingBalances(IGUniPool pool, uint256 balance)
        external
        view
        returns (uint256 amount0, uint256 amount1);

    function getPoolUnderlyingBalances(IGUniPool pool)
        external
        view
        returns (uint256 amount0, uint256 amount1);

    function getRebalanceParams(
        IGUniPool pool,
        uint256 amount0In,
        uint256 amount1In,
        uint16 slippageBPS
    )
        external
        view
        returns (
            bool zeroForOne,
            uint256 swapAmount,
            uint160 swapThreshold
        );
}
