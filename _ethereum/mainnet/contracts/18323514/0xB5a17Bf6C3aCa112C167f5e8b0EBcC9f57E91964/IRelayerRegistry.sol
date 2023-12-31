// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRelayerRegistry {
    function getRelayerBalance(address relayer) external view returns (uint256);

    function isRelayerRegistered(address relayer) external view returns (bool);
}
