// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract AntiApes is ERC721, Ownable {
    string private _baseURIextended;
    uint public currentIndex = 0;
    mapping(address => bool) public whitelistClaimed;

    constructor(string memory baseURI) ERC721("Anti Apes", "ABAYC") {
        _baseURIextended = baseURI;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    //get Total Supply
    function totalSupply() view public returns (uint){
        return currentIndex;
    }

    function mint(uint numberOfTokens) public {
        require(msg.sender == tx.origin, "No transaction from smart contracts!")
        ;require(numberOfTokens <= 5, "Can only mint 5 tokens at a time")
        ;require(currentIndex + numberOfTokens <= 9999, "Purchase would exceed max supply of")

        ;for(uint i = 0; i < numberOfTokens; i++) {
            if (currentIndex < 9999) {
                _safeMint(msg.sender, currentIndex + i);
            }
        }
        currentIndex += numberOfTokens;
    }

    /*
* Withdraw Contract Balance
*/
    
    function withdraw() public onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}
