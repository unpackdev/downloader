// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract APE is ERC721A, Ownable {
    uint256 MAX_PER_WALLET = 10;
    uint256 MAX_SUPPLY = 2222;
    uint256 public mintRate = 0.005 ether;


    string public baseURI =
        "ipfs://QmPT8zKB2crpcDeeMcogBzLcqPbFHbNtj3qW9qYAum9pKb/";

    constructor() ERC721A("JustApe", "Ape") {}

    function mint(uint256 quantity) external payable {
        if (_numberMinted(msg.sender) == 0) {
            require(quantity <= MAX_PER_WALLET, "Exceeded the limit");
            require(msg.value >= (mintRate * (quantity - 1)), "Not enough ether sent");
        } else {
            require(quantity + _numberMinted(msg.sender) <= MAX_PER_WALLET, "Exceeded the limit");
            require(msg.value >= (mintRate * quantity), "Not enough ether sent");
        }

        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");

        _safeMint(msg.sender, quantity);
    }

      function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
      }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}