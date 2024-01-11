// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ILiquidityGauge.sol";

interface IBalancerGaugeFactory {
    function getPoolGauge(address pool) external view returns (ILiquidityGauge);
}
