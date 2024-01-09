// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

import "./InternalWhitelistControl.sol";

contract WallStreetArt is ERC721URIStorage, ERC721Enumerable, InternalWhitelistControl {

    using SafeMath for uint256;
    using Strings for uint256;

    string private _baseTokenURI;
    string[] private tokenURIs;
    
    event TokenURIUpdated(uint256 indexed _tokenId, string indexed _tokenURI);

    constructor(string memory name, string memory symbol, string memory baseURI) ERC721(name, symbol) {
        _setBaseURI(baseURI);
    }

    function setTokenURIs(string[] calldata _tokenURIs) onlyOwner public {
        for(uint256 i = 0; i < _tokenURIs.length; i++) {
            tokenURIs.push(_tokenURIs[i]);
        }
    }

    function getTokenURIs() onlyOwner public view returns(string[] memory) {
        return tokenURIs;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function _beforeTokenTransfer(
        address from, 
        address to, 
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns(bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
    * @dev Changes the base URI if we want to move things in the future (Callable by owner only)
    */
    function _setBaseURI(string memory baseURI) internal {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function baseTokenURI() public view virtual returns (string memory) {
        return _baseURI();
    }

    /**
    * @dev Changes the base URI if we want to move things in the future (Callable by owner only)
    */
    function setBaseURI(string memory baseURI) onlyOwner public {
        _setBaseURI(baseURI);
    }

    /**
    * @dev Changes the base URI if we want to move things in the future (Callable by owner only)
    */
    function setTokenURI(uint256 tokenId, string memory baseURI) 
    public
    internalWhitelisted(msg.sender) {
        emit TokenURIUpdated(tokenId, baseURI);
        _setTokenURI(tokenId, baseURI);
    }

    /**
    * @dev Changes the base URI if we want to move things in the future (Callable by owner only)
    */
    function mint( address to, uint256 tokenId) 
    public
    internalWhitelisted(msg.sender) {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURIs[tokenId]);
    }

}