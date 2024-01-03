// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

// https://github.com/curvefi/curve-contract/blob/master/contracts/gauges/LiquidityGauge.vy
interface Gauge {
    function deposit(uint) external;

    function balanceOf(address) external view returns (uint);

    function withdraw(uint) external;
}
