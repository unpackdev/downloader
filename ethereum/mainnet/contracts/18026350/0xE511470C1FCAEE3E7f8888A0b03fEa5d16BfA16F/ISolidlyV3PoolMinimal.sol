// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ISolidlyV3PoolMinimal {
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    function token0() external view returns (address);

    function token1() external view returns (address);
}
