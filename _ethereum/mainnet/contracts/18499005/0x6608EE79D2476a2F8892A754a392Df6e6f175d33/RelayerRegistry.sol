// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IRelayerRegistry {
    function unregisterRelayer(address relayer) external;

    function registerRelayerAdmin(address relayer, string calldata ensName, uint256 stake) external;

    function setOperator(address newOperator) external;

    function getRelayerBalance(address relayer) external view returns (uint256);
}
