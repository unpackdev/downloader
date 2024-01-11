// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC721.sol";


/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStoragePB is ERC721 {
    using Strings for uint256;

    event PermanentURI(string value, uint256 indexed id);

    uint8 public constant FROZEN_BIT_INDEX = 0;
    uint8 public constant ABSOLUTE_BIT_INDEX = 1;

    // Optional mapping for token URIs
    mapping(uint256 => uint256) private _tokenURIFlags;
    mapping(uint256 => string) private _tokenURIs;

    string private _baseTokenURI;


    // Enable URI handling

    function _baseURI()
        internal
        view
        virtual
        override(ERC721)
        returns (string memory)
    {
        return _baseTokenURI;
    }

    function _setBaseURI(string calldata baseURI_)
        internal
        virtual
    {
        _baseTokenURI = baseURI_;
    }


    function _setBaseURIm(string memory baseURI_)
        internal
        virtual
    {
        _baseTokenURI = baseURI_;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "tokeId doesn't exist");

        uint256 uriFlags = _tokenURIFlags[tokenId];
        string storage uri = _tokenURIs[tokenId];

        if (uriFlags > 0) {
            return uri;
        }

        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return uri;
        }

        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(uri).length > 0) {
            return string(abi.encodePacked(base, uri));
        }

        return super.tokenURI(tokenId);
    }

    function _getTokenURIFlags(uint256 tokenId)
        internal
        view
        virtual
        returns (uint256)
    {
        return _tokenURIFlags[tokenId];
    }

    function _isFlagSet(uint256 flags, uint8 bit_index) internal pure returns (bool)
    {
        return ((flags >> bit_index) & uint256(1)) > 0;
    }

    function _setFlag(uint256 flags, uint8 bit_index, bool value) internal pure returns (uint256)
    {
        if (value) {
            return flags | (uint256(1) << bit_index);
        }

        return flags & (~(uint256(1) << bit_index));
    }

    function _requireNotFrozen(uint256 tokenId) internal view returns (uint256)
    {
        uint256 uriFlags = _tokenURIFlags[tokenId];
        require(!_isFlagSet(uriFlags, FROZEN_BIT_INDEX), "URI has been frozen");
        return uriFlags;
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist and URI must *NOT* be frozen.
     */
    function _setTokenURI(uint256 tokenId, string calldata _tokenURI, bool absolute) internal virtual {
        require(_exists(tokenId), "Setting URI to nonexistent token");

        uint256 uriFlags = _requireNotFrozen(tokenId);
        _tokenURIs[tokenId] = _tokenURI;
        _tokenURIFlags[tokenId] = _setFlag(uriFlags, ABSOLUTE_BIT_INDEX, absolute);
    }

    function _freezeTokenURI(uint256 tokenId) internal virtual
    {
        require(_exists(tokenId), "URI freeze for nonexistent token");

        uint256 uriFlags = _requireNotFrozen(tokenId);

        string memory uri = this.tokenURI(tokenId);

        //uriFlags = _setFlag(uriFlags, FROZEN_BIT_INDEX, true);
        //_tokenURIFlags[tokenId] = _setFlag(uriFlags, ABSOLUTE_BIT_INDEX, true);
        _tokenURIFlags[tokenId] = 3;
        _tokenURIs[tokenId] = uri;

        emit PermanentURI(uri, tokenId);
    }

    /**
     * @dev Deletes `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist and URI must *NOT* be frozen.
     */
    function _deleteTokenURI(uint256 tokenId, bool requireNotFrozen) internal virtual {
        require(_exists(tokenId), "Setting URI to nonexistent token");

        uint256 flags = requireNotFrozen ? _requireNotFrozen(tokenId) : _tokenURIFlags[tokenId];

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        if (flags > 0) {
            delete _tokenURIFlags[tokenId];
        }
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        _deleteTokenURI(tokenId, false);
        super._burn(tokenId);
    }
}
