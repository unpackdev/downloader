//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";

/// @title DoAW Metadata
/// @notice https://doaw.folia.app
/// @author @okwme
/// @dev The updateable and replaceable metadata contract for DoAW and shaDoAW

contract Metadata is Ownable {
    constructor() {}

    string public baseURI = "https://doaw.folia.app/v1/metadata/";
    string public secondBasURI = "ipfs://";

    /// @dev sets the baseURI can only be called by the owner
    /// @param baseURI_ the new baseURI
    function setbaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    /**
     * @dev Sets the second base URI for metadata.
     * @param secondBaseURI_ The new second base URI.
     * Only the contract owner can call this function.
     */
    function setSecondBaseURI(string memory secondBaseURI_) public onlyOwner {
        secondBasURI = secondBaseURI_;
    }

    /**
     * @dev Generates the metadata for a given token ID.
     * @param tokenId The ID of the token.
     * @return The metadata as a string.
     */
    function getMetadata(uint256 tokenId) public view returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    /**
     * @dev Retrieves the second metadata for a given token ID.
     * @param tokenId The ID of the token.
     * @return The second metadata as a string.
     */
    function getSecondMetadata(
        uint256 tokenId
    ) public view returns (string memory) {
        return
            string(abi.encodePacked(secondBasURI, Strings.toString(tokenId)));
    }
}
