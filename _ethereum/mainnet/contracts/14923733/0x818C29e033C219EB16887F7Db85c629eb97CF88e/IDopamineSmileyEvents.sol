// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.13;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Dopamine ERC-721 smiley events interface
interface IDopamineSmileyEvents {

    /// @notice Emits when the Dopamine tab base URI is set to `baseUri`.
    /// @param baseURI The base URI of the tab contract, as a string.
    event BaseURISet(string baseURI);

    /// @notice Emits when owner is changed from `oldOwner` to `newOwner`.
    /// @param oldOwner The address of the previous owner.
    /// @param newOwner The address of the new owner.
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

}
