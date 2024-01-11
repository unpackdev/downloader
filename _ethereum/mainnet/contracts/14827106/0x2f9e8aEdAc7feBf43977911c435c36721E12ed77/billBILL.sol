// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "./Ownable.sol";
import "./ERC721A.sol";


contract billBILL is ERC721A, Ownable {
    bool public SaleIsActive;

    uint8 public constant MaxPerTransaction = 20;
    uint16 public constant MaxTokens = 3000;
    uint256 public TokenPrice = 0.03 ether;

    string private _baseTokenURI;

    modifier validMint(uint256 numTokens) {
        require(SaleIsActive, "Sale must be active in order to mint");
        require(numTokens <= MaxPerTransaction, "Higher than max per transaction");
        require(totalSupply() + numTokens <= MaxTokens, "Purchase more than max supply");
        _;
    }
    
    constructor(string memory baseURI) ERC721A("billBILL", "billBILL", MaxPerTransaction, MaxTokens) {
        _baseTokenURI = baseURI;
    }

    function withdraw() external onlyOwner {
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success);
    }

    function mint(uint256 numTokens) external payable validMint(numTokens) {        
        require(msg.value >= numTokens * TokenPrice, "Ether too low");       
        _safeMint(_msgSender(), numTokens);
    }

    function mintTo(address to, uint256 numTokens) external onlyOwner validMint(numTokens) {
        _safeMint(to, numTokens);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function toggleSaleState() external onlyOwner {
        SaleIsActive = !SaleIsActive;
    }

    function setTokenPrice(uint256 tokenPrice) external onlyOwner {
        TokenPrice = tokenPrice;
    }
           
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
}