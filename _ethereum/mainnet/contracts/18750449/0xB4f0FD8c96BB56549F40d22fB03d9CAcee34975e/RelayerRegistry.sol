// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface RelayerRegistry {
    function setMinStakeAmount(uint256 minAmount) external;
}