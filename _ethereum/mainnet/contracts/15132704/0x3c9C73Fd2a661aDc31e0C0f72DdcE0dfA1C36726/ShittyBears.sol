// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract shittyBears is ERC721A, Ownable {
    uint256 public maxMintAmountPerTxn = 100;
    uint256 public maxSupply = 5555;
    uint256 public mintPrice = 0 ether;

    string public baseURI = "";

    constructor() ERC721A("shitty bears", "shtbrs") {}

    function mint(uint256 quantity) external payable {
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(quantity > 0 && quantity <= maxMintAmountPerTxn, "Invalid mint amount!");
        require(totalSupply() + quantity <= maxSupply, "Not enough tokens left");
        require(msg.value >= (mintPrice * quantity), "Not enough ether sent");
        _safeMint(msg.sender, quantity);
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxMints(uint256 _maxMintAmountPerTxn) public onlyOwner {
        maxMintAmountPerTxn = _maxMintAmountPerTxn;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }
}