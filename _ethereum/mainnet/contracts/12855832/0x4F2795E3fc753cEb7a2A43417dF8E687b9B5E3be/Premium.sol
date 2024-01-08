// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";

import "./Ownable.sol";
import "./Pausable.sol";

import "./Counters.sol";
import "./SafeMath.sol";


contract Premium is ERC721, ERC721Burnable, ERC721Enumerable, Pausable, ERC721URIStorage, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;


    Counters.Counter private tokenIdCounter;
    string private baseURI;


    constructor (
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        baseURI = _initBaseURI;
    }


    // ***** public view *****
    function getCurrentTokenID () public view returns (uint256) {
        return tokenIdCounter.current();
    }


    function tokenURI (
        uint256 tokenId
    ) public view override (ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }


    // ***** internal *****
    function _baseURI () internal view virtual override returns (string memory) {
        return baseURI;
    }


    // ***** only owner *****
    function mint (
        address _to,
        uint256 _prefix
    ) public onlyOwner {
        uint256 prefix = _prefix.mul(1000);

        tokenIdCounter.increment();
        _safeMint(_to, prefix.add(tokenIdCounter.current()));
    }


    function mintMultiple (
        address _to,
        uint256 _prefix,
        uint256 _cnt
    ) public onlyOwner {
        for (uint256 i = 0 ; i < _cnt; i++) {
            mint(_to, _prefix);
        }
    }


    function pause () public onlyOwner {
        _pause();
    }

    
    function unpause () public onlyOwner {
        _unpause();
    }


    function setBaseURI (
        string memory _newBaseURI
    ) public onlyOwner {
        baseURI = _newBaseURI;
    }


    // ***** override *****
    function _burn (
        uint256 _tokenId
    ) internal override (ERC721, ERC721URIStorage) {
        require(ERC721.ownerOf(_tokenId) == msg.sender, "ERC721: burn of token that is not own");
        super._burn(_tokenId);
    }


    function _beforeTokenTransfer (
        address from,
        address to,
        uint256 tokenId
    ) internal whenNotPaused override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }


    function supportsInterface (
        bytes4 interfaceId
    ) public view whenNotPaused override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}