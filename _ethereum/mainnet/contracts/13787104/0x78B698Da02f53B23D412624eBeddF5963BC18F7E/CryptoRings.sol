// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";

contract CryptoRings is ERC721, Ownable {

    uint256 public tokenCount;
    bool public paused = true;
    string _baseTokenURI;
    uint256 private price = 0.10 ether;

    constructor() ERC721("CryptoRings", "CRINGS")  {
        _baseTokenURI = "https://www.thecryptorings.com/api/";
        for (uint256 i = 0; i < 25; i++) {
            _safeMint(msg.sender, i);
        }
        tokenCount += 25;
    }

    function mint(uint256 num) public payable {
        require(!paused, "Minting has not begun");
        require(num < 11, "You can only mint 10 rings");
        require(tokenCount + num < 6001, "Exceeds maximum ring supply");
        require(msg.value >= price * num, "Ether sent is not correct" );

        for(uint256 i; i < num; i++) {
            _safeMint(msg.sender, tokenCount + i);
        }
        tokenCount += num;
    }

    function setPrice(uint256 _newPrice) public onlyOwner() {
        price = _newPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function getPrice() public view returns (uint256) {
        return price;
    }

    function pause(bool val) public onlyOwner {
        paused = val;
    }

    function withdraw(uint256 amount) public payable onlyOwner {
        uint256 bal = address(this).balance;
        require(amount <= bal, "Withdrawal amount exceeds balance");
        require(payable(msg.sender).send(amount));
    }

    function withdrawAll() public payable onlyOwner {
        uint256 bal = address(this).balance;
        require(payable(msg.sender).send(bal));
    }
}