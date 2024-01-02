// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface RelayerRegistry {
    function unregisterRelayer(address relayer) external;

    function getRelayerBalance(address relayer) external view returns (uint256);
}
