// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract NFTMyWhip is ERC721Enumerable, Ownable {

    using Strings for uint256;
    
    string public baseUri = "https://www.nftmywhip.com/api/nft/";

    constructor() ERC721("NFT My Whip", "WHIP") {}

    function setBaseUri(string memory url) public onlyOwner {
        baseUri = url;
    }

    function fundWallet() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }


    function baseTokenURI() public view returns (string memory) {
      return baseUri;
    }

    function createCar() public payable {
        uint256 mintIndex = totalSupply();
        _safeMint(msg.sender, mintIndex);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId));
        return string(abi.encodePacked(
            baseTokenURI(),
            _tokenId.toString()
        ));
    }
    
    
}