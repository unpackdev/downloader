// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
contract TheSupremeCourt is ERC721A, Ownable {
    string private _baseURIextended;
    bool public saleIsActive = false;

    constructor(string memory baseURI) ERC721A("TheSupremeCourt", "TSC") {
        _baseURIextended = baseURI;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

     function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function mint(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale Not Active")
        ;require(msg.sender == tx.origin, "No Bots")
        ;require(numberOfTokens <= 5, "5 tokens at a time")
        ;require(_totalMinted() + numberOfTokens <= 7363, "Transaction Exceeds Max Supply")
        ;require(0.02 ether * numberOfTokens <= msg.value, "Value Not Correct");
        
        _mint(msg.sender, numberOfTokens);
    }

    function withdraw() public onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}

// 84373644482322876632426476
