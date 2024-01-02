// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.21;

interface IPoolPositionSlim {
    /// @notice Amount of pool.tokenA() and pool.tokenB() tokens held by the
    //PoolPosition
    //  @return reserveA Amount of pool.tokenA() tokens held by the
    //  PoolPosition
    //  @return reserveB Amount of pool.tokenB() tokens held by the
    //  PoolPosition
    function getReserves() external view returns (uint256 reserveA, uint256 reserveB);
}