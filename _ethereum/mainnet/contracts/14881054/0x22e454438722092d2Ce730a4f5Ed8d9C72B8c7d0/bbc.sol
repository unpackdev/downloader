// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract BBC is Ownable, ERC721A {
    uint public constant MAX_SUPPLY = 3500;
    bool public isPaused = false;
    
    uint public batchSize;
    string public baseTokenURI;

    constructor(uint batchSize_, string memory baseTokenURI_) ERC721A("Big Brick Club", "BBC") {
        batchSize = batchSize_;
        baseTokenURI = baseTokenURI_;
    }

    function togglePause() public onlyOwner {
        isPaused = !isPaused;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseTokenURI_) public onlyOwner{
        baseTokenURI = baseTokenURI_;
    }

    function mint(uint amount) public payable {
        require(!isPaused, "Mint is not live");
        require(totalSupply() + amount <= MAX_SUPPLY, "Mint amount exceeds total brick count");
        require(amount <= batchSize, "Amount cannot be more than 20");
        require(tx.origin == msg.sender, "No contracts allowed");

        _mint(msg.sender, amount);
    } 

    // Just in case something strange goes on and somebody sends money here somehow
    function withdraw() public payable onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transer failed.");
    }
}