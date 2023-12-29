// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/// @title IAfterTokenTransfersHook
/// @dev Interface that defines hooks to be executed After token transfers.
interface IAfterTokenTransfersHook {
    /**
     * @notice Emitted when the after token transfers hook is used.
     * @param from Address from which the tokens are being transferred.
     * @param to Address to which the tokens are being transferred.
     * @param startTokenId The starting ID of the tokens being transferred.
     * @param quantity The number of tokens being transferred.
     */
    event AfterTokenTransfersHookUsed(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    );

    /**
     * @notice Provides a custom implementation for the token transfers process.
     * @param from Address from which the tokens are being transferred.
     * @param to Address to which the tokens are being transferred.
     * @param startTokenId The starting ID of the tokens being transferred.
     * @param quantity The number of tokens being transferred.
     */
    function afterTokenTransfersHook(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) external;
}
