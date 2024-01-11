// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "./Ownable.sol";
import "./ERC721A.sol";

contract Milords is ERC721A, Ownable {
    uint8 public constant MaxPerTransaction = 10;
    uint16 public constant MaxFreeTokens = 600;
    uint16 public constant MaxTokens = 10000;
    uint256 public TokenPrice = 0.0088 ether;
    string private _baseTokenURI;
    
    constructor(string memory baseURI) ERC721A("Milords", "LORD", MaxPerTransaction, MaxTokens) {
        _baseTokenURI = baseURI;
    }

    function withdraw() external onlyOwner {
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success);
    }

    function mint(uint256 numTokens) external payable {
        require(numTokens <= MaxPerTransaction, "Higher than max per transaction");
        require(totalSupply() + numTokens <= MaxTokens, "Purchase more than max supply");
        if (totalSupply() >= MaxFreeTokens) require(msg.value >= numTokens * TokenPrice, "Ether too low");          
        _safeMint(_msgSender(), numTokens);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setTokenPrice(uint256 tokenPrice) external onlyOwner {
        TokenPrice = tokenPrice;
    }
           
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
}