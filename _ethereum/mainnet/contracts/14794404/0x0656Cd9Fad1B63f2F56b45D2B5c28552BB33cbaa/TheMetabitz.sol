// SPDX-License-Identifier: MIT
// Creator: Luca Di Domenico - https://twitter.com/luca_dd7

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract TheMetabitz is ERC721A, Ownable {
    
    uint32 private _maxSupply = 46;
    string private baseURI = "https://metabitz-metadata.herokuapp.com/api/lands/";

    constructor() ERC721A("The Metabitz", "M2BITZ (X,Y)") {}

    function mint(address to, uint256 quantity) external payable onlyOwner {
        require(totalSupply() + quantity <= _maxSupply, "The total supply limit has been reached.");
        _safeMint(to, quantity);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        baseURI = uri;
    }
}
