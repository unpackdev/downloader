// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./SafeMath.sol";

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract RichPiggySociety is ERC721, Ownable {
    
    using SafeMath for uint256;

    using Strings for uint256;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string private baseURI;

    uint256 public constant price = 0.005 ether;

    uint public constant maxPurchase = 20;

    uint256 public constant MAX = 10000;

    bool public saleIsActive = false;

    constructor(string memory _baseURI) ERC721("Rich Piggy Society", "RPC") { 
        setBaseURI(_baseURI);
    }

    
    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }
    
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    
    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory){
        require(_exists(tokenId), "Token does not exist.");        
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }    
    
    function mint(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint ");
        require(numberOfTokens > 0 && numberOfTokens <= maxPurchase, "Can only mint 20 tokens at a time");
        require(totalSupply().add(numberOfTokens) <= MAX, "Purchase would exceed the max supply");  
        require(msg.value >= price.mul(numberOfTokens), "Ether value sent is not correct");           

        for(uint i = 0; i < numberOfTokens; i++) {                  
            if (totalSupply() < MAX) {
                _tokenIds.increment();  
                uint mintIndex = totalSupply();                 
                _safeMint(msg.sender, mintIndex);
            }
        }
    }
}