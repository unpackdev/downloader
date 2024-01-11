// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract Strokes is Ownable, ERC721A {

    uint256 public constant SUPPLY = 3000;
    uint256 public maxMint = 3;
    bool public mintActive = false;
    string public _tokenBaseURI;
    bool public testMint = false;

    constructor() ERC721A ("StrokesNFT","STRO") {}

    function mint(uint256 quantity) external {
        require(totalSupply() < SUPPLY, "We are sold out!");
        require(mintActive, "Mint is Paused");
        require(quantity > 0, "Minimum mint is 1");
        require(quantity <= maxMint, "Exceeds max mint.");
        require( totalSupply() + quantity <= SUPPLY, "Exceeds max supply.");
        _safeMint(msg.sender, quantity);
    }

    function testMintFn() external onlyOwner {
        require( !testMint, "Test mint already executed.");
        _safeMint(msg.sender, 1);
        testMint = true;
    }
    
    function toggleMintActive() external onlyOwner {
        mintActive = !mintActive;
    }
    

    function setMaxMint(uint256 _maxMint) external onlyOwner {
        maxMint = _maxMint;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _tokenBaseURI = baseURI;
    }

    function _baseURI() override internal view virtual returns (string memory) {
        return _tokenBaseURI;
    }
}