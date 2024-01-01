// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IRelayerRegistryProxy {
    function upgradeTo(address newImplementation) external;
}