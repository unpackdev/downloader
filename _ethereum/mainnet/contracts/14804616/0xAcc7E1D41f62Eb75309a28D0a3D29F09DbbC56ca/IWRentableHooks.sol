// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;

// Inheritance
import "./IRentableHooks.sol";

/// @title WToken Rentable Hooks
/// @author Rentable Team <hello@rentable.world>
/// @custom:security Rentable Security Team <security@rentable.world>
interface IWRentableHooks is IRentableHooks {
    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @dev Notify the implementer about a token transfer
    /// @param tokenAddress wrapped token address
    /// @param from sender
    /// @param to receiver
    /// @param tokenId wrapped token id
    function afterWTokenTransfer(
        address tokenAddress,
        address from,
        address to,
        uint256 tokenId
    ) external;
}
