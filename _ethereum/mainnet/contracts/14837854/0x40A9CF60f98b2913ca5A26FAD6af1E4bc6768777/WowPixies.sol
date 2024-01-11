// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract NotOkayChimps is ERC721, Ownable {
    string private _baseURIextended;
    uint public currentIndex = 1;
    bool public saleIsActive = false;

    constructor(string memory baseURI) ERC721("Not Okay Chimps", "NOC") {
        _baseURIextended = baseURI;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function totalSupply() view public returns (uint){
        return currentIndex;
    }

     function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function mint(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint")
        ;require(msg.sender == tx.origin, "No transaction from smart contracts!")
        ;require(numberOfTokens <= 50, "Can only mint 50 tokens at a time")
        ;require(currentIndex + numberOfTokens <= 5555, "Purchase would exceed max supply of")
        ;if(currentIndex + numberOfTokens > 555){
            require(0.02 ether * numberOfTokens <= msg.value, "Ether value sent is not correct");
        }

        for(uint i = 0; i < numberOfTokens; i++) {
            if (currentIndex < 5555) {
                _safeMint(msg.sender, currentIndex + i);
            }
        }
        currentIndex += numberOfTokens;
    }

    function withdraw() public onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}
