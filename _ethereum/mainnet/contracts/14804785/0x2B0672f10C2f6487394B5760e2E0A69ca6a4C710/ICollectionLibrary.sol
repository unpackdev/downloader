// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;

/// @title Collection library interface
/// @author Rentable Team <hello@rentable.world>
/// @notice Implementer can realize custom logic for specific collections attaching to these hooks
interface ICollectionLibrary {
    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @notice Called after a deposit
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    /// @param user depositor
    function postDeposit(
        address tokenAddress,
        uint256 tokenId,
        address user
    ) external;

    /// @notice Called after a listing
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    /// @param user lister
    /// @param maxTimeDuration max duration allowed for the rental
    /// @param pricePerSecond price per second in payment token units
    function postList(
        address tokenAddress,
        uint256 tokenId,
        address user,
        uint256 minTimeDuration,
        uint256 maxTimeDuration,
        uint256 pricePerSecond
    ) external;

    /// @notice Called after a rent
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    /// @param duration rental duration
    /// @param from rentee
    /// @param to renter
    /// @param toWallet renter wallet
    function postRent(
        address tokenAddress,
        uint256 tokenId,
        uint256 duration,
        address from,
        address to,
        address payable toWallet
    ) external payable;

    /// @notice Called after expiration settlement on-chain
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    /// @param from rentee
    function postExpireRental(
        address tokenAddress,
        uint256 tokenId,
        address from
    ) external payable;

    /// @notice Called after WToken transfer
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    /// @param from sender
    /// @param to receiver
    /// @param toWallet receiver wallet
    function postWTokenTransfer(
        address tokenAddress,
        uint256 tokenId,
        address from,
        address to,
        address payable toWallet
    ) external;

    /// @notice Called after OToken transfer
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    /// @param from sender
    /// @param to receiver
    /// @param currentRenterWallet current renter wallet
    /// @param rented true when a rental is in place, false otw
    function postOTokenTransfer(
        address tokenAddress,
        uint256 tokenId,
        address from,
        address to,
        address payable currentRenterWallet,
        bool rented
    ) external;
}
