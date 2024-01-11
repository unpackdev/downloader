// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract MutantGoblinYachtClub is ERC721A, Ownable {
    uint256 MAX_MINTS = 20;
    uint256 MAX_SUPPLY = 9999;
    uint256 public mintRate = 0 ether;

    string public baseURI = "ipfs://QmRfEaiGRAPjTsytCdtZt3KXGXJNutFSPKFhJcePHw2212/hidden.json";

    constructor() ERC721A("MutantGoblinYachtClub", "MGYC") {}

    function mint(uint256 quantity) external payable {
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(quantity + _numberMinted(msg.sender) <= MAX_MINTS, "Exceeded the limit");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        require(msg.value >= (mintRate * quantity), "Not enough ether sent");
        _safeMint(msg.sender, quantity);
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setMintRate(uint256 _mintRate) public onlyOwner {
        mintRate = _mintRate;
    }
}