// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract AB1 is ERC721, ERC721Enumerable, Ownable {

    string public baseURI;

    constructor() ERC721("Asprey Bugatti La Voiture Noire 1:1", "AB:1") {
        baseURI = "https://asprey-nft-minting-metadata-ab-01.s3.eu-west-2.amazonaws.com/1of1/";
        _safeMint(_msgSender(), 1);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    function setBaseURI(string calldata _URI) external onlyOwner {
        baseURI = _URI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
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