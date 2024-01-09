// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract Fazuki is ERC721Enumerable, ReentrancyGuard, Ownable {
    string _baseUri;
    string _contractUri;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public price = 0.01 ether;
    uint256 public maxFreeMint = 1337;
    uint256 public maxMintPerTransaction = 20;

    constructor() ERC721("Fazuki", "FAZUKI") Ownable() {
        _contractUri = "ipfs://QmRiu6cqpvE7uqCzbPTsd1cXTpGtndiD7VDvnCJm22F4Sb";
        _baseUri = "ipfs://QmVUNk7j8Rz8vDbMQ2JbxHWN6kp9VKRdpQtBEM3yAGxAbQ";
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function mint(uint256 amount) external payable nonReentrant {
        require(amount <= maxMintPerTransaction, "Max mints per txn exceeded");
        require(totalSupply() + amount <= MAX_SUPPLY, "Sold out");
        if (totalSupply() + amount > maxFreeMint && totalSupply() + amount <= 4000) {
            require(msg.value >= price * amount, "Ether send is under price");
        }
        else if (totalSupply() + amount > 4000 && totalSupply() + amount <= 8000) {
            uint256 price2 = 0.02 ether;
            require(msg.value >= price2 * amount, "Ether send is under price");
        }
        else if (totalSupply() + amount > 8000) {
            uint256 price3 = 0.03 ether;
            require(msg.value >= price3 * amount, "Ether send is under price");
        }
        uint256 supply = totalSupply();
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, supply  + i);
        }
    }

    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseUri = newBaseURI;
    }

    function setContractURI(string memory newContractURI) external onlyOwner {
        _contractUri = newContractURI;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function withdraw() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance), "Cannot withdraw!");
    }
}