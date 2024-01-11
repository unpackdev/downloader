// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.10;

import "./ERC721A.sol";
import "./Ownable.sol";

contract TouchGrass is ERC721A, Ownable {
    
    string public baseURI = "ipfs://QmdzdGQ6kCywHeE6jKqeFdoY6ZgPgiEtMTuU6t9XDUJMzC";
    
    uint16 MAX_GRASS = 2500;
    uint16 MAX_MINT_QTY = 5;
    uint16 GRASS_COUNT = 0;

    constructor() ERC721A("Touch Grass", "GRASS") {}

    function setBaseURI(string memory base) public onlyOwner {
        baseURI = base;
    }

    function mint(uint16 quantity) public {
        require(quantity > 0, "You have to mint at least one grass!");
        require(quantity <= MAX_MINT_QTY, "You can't mint that many grass at a time!");
        require(GRASS_COUNT + quantity <= MAX_GRASS, "All grass has already been minted!");
       _safeMint(msg.sender, quantity);
        GRASS_COUNT += quantity;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A) returns (string memory) {
        return string(abi.encodePacked(baseURI));
    }
}