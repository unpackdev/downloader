// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: X by Pak
/// @author: manifold.xyz

import "./IERC721.sol";

interface IX is IERC721 {
    /**
     * @dev Mint (sequential). Will set the metadata location
     * to the default uri + tokenId.  Only callable by contract owner.
     */
    function mint(address to) external;

    /**
     * @dev Mint. Pass in the metadata locations.
     * Only callable by contract owner.
     */
    function mint(address to, string calldata uri) external;

    /**
     * @dev Batch mint (sequential). Will set the metadata location
     * to the default uri + tokenId.  Only callable by contract owner.
     */
    function batchMint(address to, uint16 count) external;

    /**
     * @dev Batch mint (sequential). Pass in the list of metadata locations.
     * Only callable by contract owner.
     */
    function batchMint(address to, string[] calldata uris) external;

    /**
     * @dev Sets the default uri. Will make it so tokenURI returns
     * "uri+tokenId".  You usually set this to a server that can dynamically
     * serve metadata.  Only callable by contract owner.
     */
    function setDefaultURI(string calldata uri) external;

    /**
     * @dev Set the metadata uri for a given tokenId.  Only callable by contract owner.
     */
    function setTokenURI(uint256 tokenId, string calldata uri) external;

    /**
     * @dev Batch set the metadata uri for a bunch of tokenIds.  Only callable by contract owner.
     */
    function setTokenURIs(uint256[] calldata tokenIds, string[] calldata uris) external;

}
