// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract MegabyteMoonboys is ERC721("Megabyte Moonboys", "MB"), Ownable, ERC721Enumerable {
    
    uint256 tokenCounter;
    uint256 public price = 10000000000000000; // 0.01 ether
    uint256 public MAX_TOKENS = 2003;
    string private baseURI;
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }
    
    function mint() public payable {
        require(tokenCounter < MAX_TOKENS, "ERC721: Max supply is 2003");
        require(msg.value == price, "The price of the NFT is 0.01 ether");
        _safeMint(_msgSender(), tokenCounter);
        tokenCounter = tokenCounter + 1;
    }
    
    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    function withdraw() onlyOwner external {
        payable(owner()).transfer(address(this).balance);
    }
}