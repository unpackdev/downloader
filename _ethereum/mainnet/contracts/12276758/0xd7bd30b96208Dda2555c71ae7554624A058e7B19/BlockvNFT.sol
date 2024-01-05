//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";

contract BlockvNFT is ERC721, ERC721Enumerable, Ownable {
    using Strings for uint256;

    string private _baseTokenURI;

    constructor(string memory name, string memory symbol, string memory baseTokenURI) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI; 
    }

    function mint(address to, uint256 tokenId) public virtual {
        require(_msgSender() == owner());
        super._safeMint(to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseTokenURI) public virtual {
        require(_msgSender() == owner());
        _baseTokenURI = baseTokenURI; 
    }

    function _baseURI() internal view virtual override(ERC721) returns (string memory) {
        return _baseTokenURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
