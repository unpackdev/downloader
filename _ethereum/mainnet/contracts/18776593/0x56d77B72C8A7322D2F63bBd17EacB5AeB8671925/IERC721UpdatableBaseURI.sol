// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Interface for ERC721 contracts which use a baseURI string
 *  to generate the tokenURI programmatically. It provides essential
 *  functions for managing the baseURI string.
 * @dev The ERC-165 identifier for this interface is 0xb8382a4b
 * @author Freeverse.io, www.freeverse.io
 */
interface IERC721UpdatableBaseURI {
    /**
     * @dev The method cannot be called if the baseURI is already locked
     */
    error BaseURIAlreadyLocked();

    /**
     * @notice Event emitted on update of the baseURI
     * @param newBaseURI the newly set baseURI
     */
    event UpdatedBaseURI(string newBaseURI);

    /**
     * @notice Event emitted on permanent lock of baseURI
     * @param baseURI the baseURI that is now permanently locked
     */
    event LockedBaseURI(string baseURI);

    /**
     * @notice Returns true if the baseURI is permanently locked
     * @return true if the baseURI is permanently locked
     */
    function isBaseURILocked() external view returns (bool);

    /**
     * @notice Updates the baseURI that is used to build the tokenURIs
     * @dev Only the owner of the ERC721 must be authorized to call this method
     * @param newBaseURI the baseURI to be used to build the tokenURIs
     */
    function updateBaseURI(string calldata newBaseURI) external;

    /**
     * @notice Prevents any further change of the baseURI, permanently, by any actor
     * @dev Only the owner of the ERC721 must be authorized to call this method
     */
    function lockBaseURI() external;
}
