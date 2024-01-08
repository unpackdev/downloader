// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Operatable.sol";
import "./Strings.sol";
import "./IERC721Metadata.sol";

abstract contract ERC721Metadata is IERC721Metadata, ERC721, Operatable {
    using Strings for uint256;

    string private _defaultURI;
    string private baseURI;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    event UpdateDefaultURI(string defaultURI);
    event UpdateBaseURI(string baseURI);
    event UpdateTokenURI(uint256 tokenId, string tokenURI);

    constructor(string memory name_, string memory symbol_, string memory defaultURI_) 
        ERC721(name_, symbol_) {
        setDefaultURI(defaultURI_);
    }

    function setDefaultURI(string memory defaultURI_) public onlyOperator() {
        _defaultURI = defaultURI_;
        emit UpdateDefaultURI(_defaultURI);
    }

    function setBaseURI(string memory baseURI_) public onlyOperator() {
        baseURI = baseURI_;
        emit UpdateBaseURI(baseURI_);
    }

    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "getTokenURI query for nonexistent token");

        return _tokenURIs[tokenId];
    }

    // set specific uri by tokenID
    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOperator() {
        require(_exists(tokenId), "setTokenURI query for nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
        emit UpdateTokenURI(tokenId, _tokenURI);
    }

    function tokenURI(uint256 tokenId) virtual public view override(IERC721Metadata, ERC721) returns (string memory) {
        string memory _tokenURI = getTokenURI(tokenId);

        // baseURI + sepecific _tokenURI
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(baseURI, tokenId.toString()));
        }

        // If there is no tokenURI, defaultURI + tokenID
        return string(abi.encodePacked(_defaultURI, tokenId.toString()));
    }

}
