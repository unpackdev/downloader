// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";

/** @title LivingFragments */
contract LivingFragments is ERC721Enumerable, Ownable {

    uint256 public constant maxSupply = 50;
    string private currentBaseURI;

    event Received(address, uint);

    constructor() ERC721("LivingFragments", "LF") {
    }

    /** @dev Mints a token
    * @param quantity The quantity of tokens to mint
    */
    function mint(uint256 quantity) public onlyOwner {
        uint supply = totalSupply();
        /// Disallow transactions that would exceed the maxSupply
        require(supply + quantity <= maxSupply, "Supply is exhausted");
        /// mint the requested quantity
        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = totalSupply();
            _safeMint(msg.sender, tokenId);
        }
    }

    /** @dev Update the base URI
    * @param baseURI_ New value of the base URI
    */
    function setBaseURI(string memory baseURI_) public onlyOwner {
        currentBaseURI = baseURI_;
    }
    
    /** @dev Get the current base URI
    * @return currentBaseURI
    */
    function _baseURI() internal view virtual override returns (string memory) {
        return currentBaseURI;
    }
}