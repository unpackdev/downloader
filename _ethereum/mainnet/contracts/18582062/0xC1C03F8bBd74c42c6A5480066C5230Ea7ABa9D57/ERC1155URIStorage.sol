// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./Strings.sol";
import "./ERC1155.sol";

abstract contract ERC1155URIStorage is ERC1155 {
    
    using Strings for uint256;

    mapping(uint256 => string) internal _tokenURIs;
    mapping(uint256 => uint256) internal supply;

    string private _uri = "";

    string private uriSuffix = ".json";

    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseuri(tokenId);

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI, uriSuffix));
        }

        return super.uri(tokenId);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC1155URIStorage: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    function burn_(uint256 tokenId) internal virtual {
        super._burn(msg.sender, tokenId, 1);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return supply[tokenId] > 0;
    }

    function getSupply(uint256 tokenId) public view returns (uint256) {
        return supply[tokenId];
    }

    function baseuri(uint256) internal view virtual returns (string memory) {
        return _uri;
    }
}