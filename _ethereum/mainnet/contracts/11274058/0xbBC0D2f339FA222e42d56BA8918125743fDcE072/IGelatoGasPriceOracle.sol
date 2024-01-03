// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

interface IGelatoGasPriceOracle {
    function latestAnswer() external view returns (int256);
}
