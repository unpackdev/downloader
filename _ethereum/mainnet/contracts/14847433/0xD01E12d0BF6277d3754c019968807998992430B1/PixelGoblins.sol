// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "./Ownable.sol";
import "./ERC721A.sol";


contract PixelGoblins is ERC721A, Ownable {
    bool public SaleIsActive;

    uint8 public constant MaxPerTransaction = 10;
    uint8 public constant MaxPerWallet = 20;
    uint16 public constant MaxTokens = 3000;

    mapping(address => uint256) private mintCount;
    string private _baseTokenURI;

    modifier validMint(uint256 numTokens) {
        require(SaleIsActive, "Sale must be active in order to mint");
        require(numTokens <= MaxPerTransaction, "Higher than max per transaction");
        require(totalSupply() + numTokens <= MaxTokens, "Purchase more than max supply");
        require(mintCount[_msgSender()] + numTokens <= MaxPerWallet);
        _;
    }
    
    constructor(string memory baseURI) ERC721A("PIXELGOBLINTOWN", "PIXELGOBLIN", MaxPerTransaction, MaxTokens) {
        _baseTokenURI = baseURI;
    }

    function withdraw() external onlyOwner {
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success);
    }

    function mint(uint256 numTokens) external payable validMint(numTokens) {
        mintCount[_msgSender()] += numTokens;
        _safeMint(_msgSender(), numTokens);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function toggleSaleState() external onlyOwner {
        SaleIsActive = !SaleIsActive;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
}