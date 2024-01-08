// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;

/**
 * @dev Interface of extension of the ERC721 standard to allow `tokenAuthor` method.
 */
interface IERC721TokenAuthor {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function tokenAuthor(uint256 tokenId) external view returns(address);
}
