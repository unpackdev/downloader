// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract PiecesOfWhat is ERC721A, Ownable {
    string private _baseURIextended;
    bool public saleIsActive = false;

    constructor(string memory baseURI) ERC721A("PiecesOfWhat", "POWG") {
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
        require(saleIsActive, "Sale must be active to mint")
        ;require(msg.sender == tx.origin, "Humans Only Coomer(<:")
        ;require(numberOfTokens <= 3, "Can only mint 3 tokens at a time")
        ;require(_totalMinted() + numberOfTokens <= 2331, "Purchase would exceed max supply")
        ;_safeMint(msg.sender, numberOfTokens);
    }

    function withdraw() public onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}
