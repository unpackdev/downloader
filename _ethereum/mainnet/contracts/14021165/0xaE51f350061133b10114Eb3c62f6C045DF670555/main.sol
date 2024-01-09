// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";

contract upsirene is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public totalupsirenes;
    uint256 public totalCount = 1107;
    
    address private owner1 = 0xC5fB133C5B3649ff917917D42dC686D19cF906AF;
    address private owner2 = 0xaB9B7234E4C0e0Ba5F685E12714EA7707FA34a05;

    uint256 public maxBatch = 15;
    uint256 public price = 25000000000000000;

    string public baseURI;

    constructor(string memory name_, string memory symbol_, string memory baseURI_) ERC721(name_, symbol_) {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }
    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token.");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString())) : ".json";
    }

    function mint(uint256 _times) payable public {
        require(_times >0 && _times <= maxBatch, "Too much!");
        require(totalupsirenes + _times <= totalCount, "sold out");
        require(msg.value == _times * price, "value error, please check price.");
        payable(owner1).transfer(msg.value/2);
        payable(owner2).transfer(msg.value/2);
        for(uint256 i=0; i< _times; i++){
            _mint(_msgSender(), 1 + totalupsirenes++);
        }
    }  
}