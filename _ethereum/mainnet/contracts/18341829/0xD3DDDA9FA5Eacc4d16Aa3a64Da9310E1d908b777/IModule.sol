// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IModule {
    /// @notice Executes given transaction data to given address.
    /// @param to Target contract address.
    /// @param value Value of the given transaction.
    /// @param data Calldata of the transaction.
    /// @return Result of the execution.
    function handleTransaction(
        address to,
        uint256 value,
        bytes calldata data
    ) external payable returns (bytes memory);
}
