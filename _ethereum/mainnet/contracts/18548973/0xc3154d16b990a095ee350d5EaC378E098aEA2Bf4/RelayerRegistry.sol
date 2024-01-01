// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IRelayerRegistry {
    function registerRelayerAdmin(address relayer, string calldata ensName, uint256 stake) external;
}
