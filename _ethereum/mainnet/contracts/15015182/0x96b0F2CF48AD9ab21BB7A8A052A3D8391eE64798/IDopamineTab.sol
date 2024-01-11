// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import "./IDopamineTabEvents.sol";

/// @title Dopamine Membership Tab Interface
interface IDopamineTab is IDopamineTabEvents {

    /// @notice Mints a dopamine tab to the minter address.
    /// @dev This function is only callable by the minter address.
    /// @return Id of the minted tab, which is always equal to `_id`.
    function mint() external returns (uint256);

    /// @notice Mints an allowlisted tab of id `id` to the sender address if
    ///  merkle proof `proof` proves they were allowlisted with that tab id.
    /// @dev Reverts if invalid proof is provided or claimer isn't allowlisted.
    ///  The allowlist is formed using encoded tuple leaves (address, id). The
    ///  Merkle Tree JS library used: https://github.com/miguelmota/merkletreejs
    /// @param proof The Merkle proof of the claim as a bytes32 array.
    /// @param id The id of the Dopamine tab being claimed.
    function claim(bytes32[] calldata proof, uint256 id) external;

    /// @notice Creates a new Dopamine tab drop.
    /// @dev This function is only callable by the admin address, and reverts if
    ///  an ongoing drop exists, drop starting index is invalid, call is too
    //   early, drop identifier is invalid, allowlist size is too large,
    ///  drop size is too small or too large, or max capacity was reached.
    /// @param dropId The drop's id (must 1 + last drop id).
    /// @param startIndex The drop's start index (must be last `dropEndIndex`).
    /// @param dropSize The total number of tabs of the drop (incl. allowlist).
    /// @param provenanceHash An immutable provenance hash equal to the SHA-256
    ///  hash of the concatenation of all SHA-256 image hashes of the drop.
    /// @param allowlistSize The total number of allowlisted tabs of the drop.
    /// @param allowlist Merkle root comprised of allowlisted address-tab pairs.
    function createDrop(
        uint256 dropId,
        uint256 startIndex,
        uint256 dropSize,
        bytes32 provenanceHash,
        uint256 allowlistSize,
        bytes32 allowlist
    ) external;

    /// @notice Gets the admin address, which controls drop settings & creation.
    function admin() external view returns (address);

    /// @notice Gets the minter address, which controls Dopamine tab emissions.
    function minter() external view returns (address);

    /// @notice Gets the time needed to wait in seconds between drop creations.
    function dropDelay() external view returns (uint256);

    /// @notice Gets the last token id of the current drop (exclusive boundary).
    function dropEndIndex() external view returns (uint256);

    /// @notice Gets the time at which a new drop can start (if last completed).
    function dropEndTime() external view returns (uint256);

    /// @notice Retrieves the provenance hash for a drop with id `dropId`.
    /// @param dropId The id of the drop being queried.
    /// @return SHA-256 hash of all sequenced SHA-256 image hashes of the drop.
    function dropProvenanceHash(uint256 dropId) external view returns (bytes32);

    /// @notice Retrieves the metadata URI for a drop with id `dropId`.
    /// @param dropId The id of the drop being queried.
    /// @return URI of the drop's metadata as a string.
    function dropURI(uint256 dropId) external view returns (string memory);

    /// @notice Retrieves the allowlist for a drop with id `dropId`.
    /// @dev See `claim()` for details regarding allowlist generation.
    /// @param dropId The id of the drop being queried.
    /// @return The drop's allowlist, as a bytes32 merkle tree root.
    function dropAllowlist(uint256 dropId) external view returns (bytes32);

    /// @notice Retrieves the drop id of the tab with id `id`.
    /// @dev This function reverts for non-existent drops. For existing drops, 
    ///  the drop id will be returned even if a drop's tab has yet to mint.
    /// @param dropId The id of the drop being queried.
    /// @return The drop id of the queried tab.
    function dropId(uint256 dropId) external view returns (uint256);

    /// @notice Retrieves a URI describing the overall contract-level metadata.
    /// @return A string URI pointing to the tab contract metadata.
    function contractURI() external view returns (string memory);

    /// @notice Sets the minter address to `newMinter`.
    /// @param newMinter The address of the new minter.
    /// @dev This function is only callable by the admin address.
    function setMinter(address newMinter) external;

    /// @notice Sets the pending admin address to  `newPendingAdmin`.
    /// @param newPendingAdmin The address of the new pending admin.
    /// @dev This function is only callable by the admin address.
    function setPendingAdmin(address newPendingAdmin) external;

    /// @notice Assigns the `pendingAdmin` address to the `admin` address.
    /// @dev This function is only callable by the pending admin address.
    function acceptAdmin() external;

    /// @notice Sets the base URI to `newBaseURI`.
    /// @param newBaseURI The new base metadata URI to set for the collection.
    /// @dev This function is only callable by the admin address.
    function setBaseURI(string calldata newBaseURI) external;

    /// @notice Sets the final metadata URI for drop `dropId` to `dropURI`.
    /// @dev This function is only callable by the admin address, and reverts
    ///  if the specified drop `dropId` does not exist.
    /// @param dropId The id of the drop whose final metadata URI is being set.
    /// @param uri The finalized IPFS / Arweave metadata URI.
    function setDropURI(uint256 dropId, string calldata uri) external;

    /// @notice Sets the drop delay `dropDelay` to `newDropDelay`.
    /// @dev This function is only callable by the admin address, and reverts if
    ///  the drop delay is too small or too large.
    /// @param newDropDelay The new drop delay to set, in seconds.
    function setDropDelay(uint256 newDropDelay) external;

    /// @notice Updates the drop provenance hash and allowlist.
    /// @dev This function is only callable by the admin address, and will
    ///  revert when called after drop finalization (when drop URI is set).
    ///  Note: This function should NOT be called unless drop is misconfigured.
    /// @param dropId The id of the drop being queried.
    /// @param provenanceHash The drop's provenance hash (SHA-256 of images).
    /// @param allowlist Merkle root of drop's allowlisted address-NFT pairs.
    function updateDrop(
        uint256 dropId,
        bytes32 provenanceHash,
        bytes32 allowlist
    ) external;
}
