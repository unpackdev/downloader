// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract FuturingBlog is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    string private BASE_URI = "ipfs://";
    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => address) private _author;
    mapping(address => bool) private _approvedAuthors;
    
    constructor() ERC721("Futuring", "FUTURING") {}

    function safeMint(string memory uri) external {
        require(_approvedAuthors[msg.sender] == true, "You are not an approved author");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _author[tokenId] = msg.sender;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function toggleAuthor(address author) external onlyOwner {
        _approvedAuthors[author] = !_approvedAuthors[author];
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        BASE_URI = baseURI;
    }

    function authorOf(uint256 tokenId)
        external
        view
        returns (address)
    {
        return _author[tokenId];
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}