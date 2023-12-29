// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IArbitratorErrors {
    /*////////////////////////////////////////////////////////////// 
                                 Errors                              
    //////////////////////////////////////////////////////////////*/

    /// @notice caller not EOA.
    error NotEOA();

    /// @notice invalid asset.
    error InvalidAsset();

    /// @notice invalid caller.
    error InvalidCaller();

    /// @notice provided fee greater than maximum allowed.
    error MaxFeeExceeded();

    /// @notice number of seats are invalid.
    error InvalidSeatCount();

    /// @notice invalid bet size.
    error InvalidBet();

    /// @notice invalid mode.
    error InvalidMode();

    /// @notice game already started.
    error AlreadyStarted();

    /// @notice game not started.
    error NotStarted();

    /// @notice game already joined.
    error AlreadyJoined();

    /// @notice game not joined.
    error NotJoined();

    /// @notice not player's turn.
    error NotTurn();

    /// @notice game ended.
    error Ended();

    /// @notice game running.
    error Running();

    /// @notice player no longer participating.
    error PlayerNotAlive();

    /// @notice already claimed.
    error AlreadyClaimed();

    /// @notice invalid signer.
    error InvalidSigner();

    /// @notice invalid signer.
    error InvalidID();

    /// @notice invalid signer.
    error InvalidCounter();
}
