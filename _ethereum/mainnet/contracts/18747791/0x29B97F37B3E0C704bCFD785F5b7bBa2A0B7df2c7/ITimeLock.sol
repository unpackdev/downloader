// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.0;

/// @title Timelock interface
interface ITimeLock {
    function admin() external view returns (address);

    function delay() external view returns (uint256);

    function queuedTransactions(bytes32 txHash) external view returns (bool);

    function queueTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 eta)
        external
        returns (bytes32 txHash);

    function executeTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 eta)
        external
        payable
        returns (bytes memory result);

    function cancelTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 eta)
        external;

    function setPendingAdmin(address newPendingAdmin) external;

    function acceptAdmin() external;
}
