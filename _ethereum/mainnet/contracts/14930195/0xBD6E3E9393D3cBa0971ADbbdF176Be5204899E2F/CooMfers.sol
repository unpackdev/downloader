// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
//by: @RedCandleHeros
contract CooMfers is ERC721, Ownable {
    string private _baseURIextended;
    uint public currentIndex = 0;
    bool public saleIsActive = false;

    constructor(string memory baseURI) ERC721("CooMfers", "CMFRS") {
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
        ;require(msg.sender == tx.origin, "Humans Only Coomer(<:")
        ;require(numberOfTokens <= 50, "Can only mint 50 tokens at a time")
        ;require(currentIndex + numberOfTokens <= 9999, "Purchase would exceed max supply")
        ;require(0.005 ether * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for(uint i = 0; i < numberOfTokens; i++) {
            if (currentIndex < 9999) {
                _safeMint(msg.sender, currentIndex + i);
            }
        }
        currentIndex += numberOfTokens;
    }

    function withdraw() public onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}
