// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.13;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Dopamine Membership Tab Events Interface
interface IDopamineTabEvents {

    /// @notice Emits when the Dopamine tab base URI is set to `baseUri`.
    /// @param baseUri The base URI of the Dopamine tab contract, as a string.
    event BaseURISet(string baseUri);

    /// @notice Emits when a new drop is created by the Dopamine tab admin.
    /// @param dropId The id of the newly created drop.
    /// @param startIndex The id of the first tabincluded in the drop.
    /// @param dropSize The number of tabs to distribute in the drop.
    /// @param allowlistSize The number of allowlisted tabs in the drop.
    /// @param allowlist A merkle root of the included address-tab pairs.
    /// @param provenanceHash SHA-256 hash of combined image hashes in the drop.
    event DropCreated(
        uint256 indexed dropId,
        uint256 startIndex,
        uint256 dropSize,
        uint256 allowlistSize,
        bytes32 allowlist,
        bytes32 provenanceHash
    );

    /// @notice Emits when a new drop delay `dropDelay` is set.
    /// @param dropDelay The new drop delay to set, in seconds.
    event DropDelaySet(uint256 dropDelay);

    /// @notice Emits when a new drop size `dropSize` is set.
    /// @param dropId The id of the queried drop.
    /// @param provenanceHash The drop collection provenance hash.
    /// @param allowlist Merkle root of drop's allowlisted address-tab pairs.
    event DropUpdated(uint256 indexed dropId, bytes32 provenanceHash, bytes32 allowlist);

    /// @notice Emits when the drop of id `id` has its URI set to `dropUr1`.
    /// @param id  The id of the drop whose URI was set.
    /// @param dropUri The metadata URI of the drop, as a string.
    event DropURISet(uint256 indexed id, string dropUri);

    /// @notice Emits when a new pending admin `pendingAdmin` is set.
    /// @param pendingAdmin The new address of the pending admin that was set.
    event PendingAdminSet(address pendingAdmin);

    /// @notice Emits when minter is changed from `oldMinter` to `newMinter`.
    /// @param oldMinter The address of the previous minter.
    /// @param newMinter The address of the new minter.
    event MinterChanged(address indexed oldMinter, address indexed newMinter);

    /// @notice Emits when admin is changed from `oldAdmin` to `newAdmin`.
    /// @param oldAdmin The address of the previous admin.
    /// @param newAdmin The address of the new admin.
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);

}
