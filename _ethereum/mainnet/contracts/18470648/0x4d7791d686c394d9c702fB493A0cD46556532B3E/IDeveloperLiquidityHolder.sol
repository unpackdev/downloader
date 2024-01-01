// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IDeveloperLiquidityHolder {
    function setLiquidityOwner(address _liquidityOwner) external;
    function provideBDLLiquidity(int24 tickFromLO) external returns (bool);
}
