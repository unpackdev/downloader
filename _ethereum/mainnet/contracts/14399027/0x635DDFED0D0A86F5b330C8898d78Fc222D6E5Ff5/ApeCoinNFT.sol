// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./ERC721.sol";
import "./Ownable.sol";

contract ApeCoinNFT is ERC721, Ownable {
    string private baseURI;
    bool public hasMinted;

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
    {}

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function mintLogo() external onlyOwner {
        require(!hasMinted, "Logo already minted"); 
        hasMinted = true;
        _safeMint(msg.sender, 0);        
    }
}
