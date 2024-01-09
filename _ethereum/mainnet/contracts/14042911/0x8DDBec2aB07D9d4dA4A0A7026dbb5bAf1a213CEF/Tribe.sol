// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract TribeU is ERC721, Ownable {
    using Counters for Counters.Counter;
    uint256 public cost;
    uint256 public maxSupply = 2500;
    string public baseTokenURI;
    Counters.Counter private supply;

    constructor(string memory baseURI, uint256 _cost) ERC721("TRIBE U", "TRIBE") {
        setBaseURI(baseURI);
        cost = _cost;
    }

    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    function mint(uint256 amount) public payable {
        require(amount > 0);
        require(supply.current() + amount <= maxSupply);
        require(msg.sender == owner() || msg.value >= cost * amount);
        for (uint256 i = 0; i < amount; i++) {
            supply.increment();
            _safeMint(msg.sender, supply.current());
        }
    }

    function setCost(uint256 newCost) public onlyOwner {
        cost = newCost;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");
        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed");
    }
}
