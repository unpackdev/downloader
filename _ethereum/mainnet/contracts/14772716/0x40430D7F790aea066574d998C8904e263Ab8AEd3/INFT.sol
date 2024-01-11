// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * A NFT interface with functions to
 * check ownership of erc721 and erc1155 tokens
 */

interface INFT {
    /**
     * Check the balance of a given token for
     * an address on ERC1155 tokens
     */
    function balanceOf(address _owner, uint256 _id)
        external
        view
        returns (uint256);

    /**
     * Check the balance of a given token for ERC721 tokens
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);
}
