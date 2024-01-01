// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @dev Interface of the Something's Fishy token
 */
interface ISFToken {
    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);
}