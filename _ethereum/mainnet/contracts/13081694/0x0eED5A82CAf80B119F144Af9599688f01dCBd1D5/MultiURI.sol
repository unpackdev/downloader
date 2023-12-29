// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Strings.sol";

abstract contract MultiURI {
    using Strings for string;

    // Mutli-token URIs where the URI will be baseTokenURI + tokenURI identified by tokenId. For example baseTokenURI could be ipfs:// and tokenURI could be the ipfs identifier.
    mapping(uint256 => string) private _tokenBaseURIs;
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev Returns an URI for a given token ID.
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     */
    function _tokenURI(uint256 tokenId) internal view returns (string memory) {
        return Strings.strConcat(_tokenBaseURIs[tokenId], _tokenURIs[tokenId]);
    }

    /**
     * @dev Internal function to set the base token URI for a given token.
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to set its URI
     * @param uri string URI to assign
     */
    function _setTokenBaseURI(uint256 tokenId, string memory uri) internal {
        _tokenBaseURIs[tokenId] = uri;
    }

    /**
     * @dev Internal function to set the token URI for a given token.
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to set its URI
     * @param uri string URI to assign
     */
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        _tokenURIs[tokenId] = uri;
    }

    function _clearTokenURI(uint256 tokenId) internal {
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    function _clearTokenBaseURI(uint256 tokenId) internal {
        if (bytes(_tokenBaseURIs[tokenId]).length != 0) {
            delete _tokenBaseURIs[tokenId];
        }
    }
}
