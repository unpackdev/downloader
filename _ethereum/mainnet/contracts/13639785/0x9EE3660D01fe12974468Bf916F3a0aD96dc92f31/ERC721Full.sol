// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Metadata.sol";

/**
 * @title Full ERC721 Token
 * @dev This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology.
 *
 * See https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
    function _transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        override(ERC721, ERC721Enumerable)
    {
        ERC721Enumerable._transferFrom(from, to, tokenId);
    }

    function _mint(
        address to,
        uint256 tokenId
    )
        internal
        override(ERC721, ERC721Enumerable)
    {
        ERC721Enumerable._mint(to, tokenId);
    }

    function _burn(
        address owner,
        uint256 tokenId
    )
        internal
        override(ERC721, ERC721Enumerable, ERC721Metadata)
    {
        // Burn implementation of Metadata
        ERC721._burn(owner, tokenId);
        ERC721Metadata._burn(owner, tokenId);
        ERC721Enumerable._burn(owner, tokenId);
    }
}
