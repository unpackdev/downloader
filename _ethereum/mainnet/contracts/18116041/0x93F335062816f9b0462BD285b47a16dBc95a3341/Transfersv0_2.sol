// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./IBeforeTokenTransfersHook.sol";
import "./ICre8ors.sol";

/**
 ██████╗██████╗ ███████╗ █████╗  ██████╗ ██████╗ ███████╗
██╔════╝██╔══██╗██╔════╝██╔══██╗██╔═══██╗██╔══██╗██╔════╝
██║     ██████╔╝█████╗  ╚█████╔╝██║   ██║██████╔╝███████╗
██║     ██╔══██╗██╔══╝  ██╔══██╗██║   ██║██╔══██╗╚════██║
╚██████╗██║  ██║███████╗╚█████╔╝╚██████╔╝██║  ██║███████║
 ╚═════╝╚═╝  ╚═╝╚══════╝ ╚════╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝                                                       
 */
/// @title Transfer Hook for Cre8ors
/// @notice This contract defines the behavior of token transfers for the Cre8ors platform,
///         before the actual transfer.
/// @dev Implements the IBeforeTokenTransfersHook interface.
contract TransferHookv0_2 is IBeforeTokenTransfersHook {
    /// @notice Custom implementation for BeforeTokenTransfers Hook.
    /// @param from Address from which tokens are transferred.
    /// @param to Address to which tokens are transferred.
    /// @param startTokenId The starting ID of the token being transferred.
    /// @param quantity The number of tokens to transfer.
    function beforeTokenTransfersHook(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) external {
        emit BeforeTokenTransfersHookUsed(from, to, startTokenId, quantity);

        // only allow 4444 mints
        if (startTokenId + quantity > 4445) {
            revert ICre8ors.Cre8ors_4444();
        }
    }
}
