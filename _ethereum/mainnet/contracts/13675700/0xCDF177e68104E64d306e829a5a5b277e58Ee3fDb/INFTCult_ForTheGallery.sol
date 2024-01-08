// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title INFTCult_V1_Thin
 * @author @NiftyMike, NFT Culture
 * @dev Super thin interface definition to enable ownership checking and forge component
 * retrieval.
 */
interface INFTCult_ForTheGallery {
    function ownerOf(uint256 tokenId) external view returns (address);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}
