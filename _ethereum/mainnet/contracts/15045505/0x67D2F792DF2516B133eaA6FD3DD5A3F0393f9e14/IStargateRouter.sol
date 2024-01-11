/// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;

interface IStargateRouter {
    function addLiquidity(
        uint256 _poolId,
        uint256 _amountLD,
        address _to
    ) external;
}
