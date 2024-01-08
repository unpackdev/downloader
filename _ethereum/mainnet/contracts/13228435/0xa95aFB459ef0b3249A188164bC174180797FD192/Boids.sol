// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./console.sol";
import "./ERC721URIStorage.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract Boids is ERC721URIStorage, Ownable {
    using SafeMath for uint256;

    uint256 public constant boidPrice = 30000000000000000; //0.03 eth
    uint public constant maxBoidPurchase = 20;
    uint256 public totalSupply = 0; 

    bool public saleIsActive = false;
    uint256 public MAX_BOIDS = 2000;

    string private _baseTokenURI;

    constructor(string memory baseURI) ERC721("BOIDS", "BOIDS") { 
        setBaseURI (baseURI);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setMaxBoids (uint newMaxBoids) public onlyOwner {
        MAX_BOIDS = newMaxBoids;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function mintOwner (uint numberOfTokens) public onlyOwner {
        require(numberOfTokens > 0 && numberOfTokens <= maxBoidPurchase, "Can only mint 20 tokens at a time");
        require(totalSupply.add(numberOfTokens) <= MAX_BOIDS, "Purchase would exceed max supply of Boids");

        for(uint i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, totalSupply + i + 1);
        }

        totalSupply = totalSupply.add(numberOfTokens);
    }

    function mintBoid (uint numberOfTokens) public payable{
        require(saleIsActive, "Sale must be active to mint a Boid");
        require(numberOfTokens > 0 && numberOfTokens <= maxBoidPurchase, "Can only mint 20 tokens at a time");
        require(totalSupply.add(numberOfTokens) <= MAX_BOIDS, "Purchase would exceed max supply of Boids");
        require(msg.value >= boidPrice.mul(numberOfTokens), "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, totalSupply + i + 1);
        }

        totalSupply = totalSupply.add(numberOfTokens);
    }
}