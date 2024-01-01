// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IRelayerRegistry {
    function unregisterRelayer(address relayer) external;
}