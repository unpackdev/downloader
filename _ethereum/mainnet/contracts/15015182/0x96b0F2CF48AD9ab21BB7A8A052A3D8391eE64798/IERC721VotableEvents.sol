// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.13;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Dopamine ERC-721 Voting Contract Events Interface
interface IERC721VotableEvents {

    /// @notice Emits when address `delegator` has its delegate address changed
    ///  from `fromDelegate` to `toDelegate` (even if they're the same address).
    /// @param delegator Address whose delegate has changed.
    /// @param fromDelegate The original delegate of the delegator.
    /// @param toDelegate The new delegate of the delegator.
    event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );

    /// @notice Emits when `delegate` votes moves from `oldVotes` to `newVotes`.
    /// @param delegate Address of the delegate whose voting weight changed.
    /// @param oldVotes The old voting weight assigned to the delegator.
    /// @param newVotes The new voting weight assigned to the delegator.
    event DelegateVotesChanged(
        address indexed delegate,
        uint256 oldVotes,
        uint256 newVotes
    );

}
