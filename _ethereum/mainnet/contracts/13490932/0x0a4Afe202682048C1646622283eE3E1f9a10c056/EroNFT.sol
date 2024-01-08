// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC2981ContractWideRoyalties.sol";

contract EroNFT is ERC721, ERC721Enumerable, ERC721URIStorage, ERC2981ContractWideRoyalties, Ownable {
    using Strings for uint256;
    string public baseURI;

    constructor(uint _royalties, string memory _name, string memory _symbol) 
        ERC721(_name, _symbol) {
        _setRoyalties(_msgSender(), _royalties);
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
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
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC2981Base)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() 
        internal 
        view
        override(ERC721) returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }
}
