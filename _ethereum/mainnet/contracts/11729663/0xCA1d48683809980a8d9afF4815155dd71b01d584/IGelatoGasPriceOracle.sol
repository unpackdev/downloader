// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IGelatoGasPriceOracle {
    function latestAnswer() external view returns (int256);
}
