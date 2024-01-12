// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";

interface IEcoNFT is IERC721 {
	
    /**
     * @dev Returns the level of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getLevel(uint256 tokenId) external view returns (uint256);
}

