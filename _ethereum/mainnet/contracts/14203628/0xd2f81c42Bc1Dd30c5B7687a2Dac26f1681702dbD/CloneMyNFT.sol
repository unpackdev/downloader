// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract CloneMyNFT is ERC721Enumerable, Ownable {

    using Strings for uint256;
    
    string public baseUri = "https://www.clonemynft.com/api/nft/";

    constructor() ERC721("CloneMyNFT", "CLONE") {}

    function withdrawBalance() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setBaseUri(string memory url) public onlyOwner {
        baseUri = url;
    }

    function baseTokenURI() public view returns (string memory) {
      return baseUri;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId));
        return string(abi.encodePacked(
            baseTokenURI(),
            _tokenId.toString()
        ));
    }
    
    function createClone() public payable {
        uint256 mintIndex = totalSupply();
        _safeMint(msg.sender, mintIndex);
    }
}