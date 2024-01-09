// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract GracieDAO is ERC721Enumerable, ReentrancyGuard, Ownable {
    string _baseUri;
    string _contractUri;

    uint256 public constant MAX_SUPPLY = 1337;
    uint256 public price = 0.01337 ether;
    uint256 public maxMintPerTransaction = 13;

    constructor() ERC721("GracieDAO", "GracieDAO") Ownable() {
        _contractUri = "ipfs://QmQfUVVfBse1Z1oGHym8dUt9ruyAevCXmvJJjtvUiFod2C";
        _baseUri = "ipfs://QmdZQg2AwTBLRZrKxkY69cf3LpDvmPm376cEoU5yLWWX1B/";
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function mint(uint256 amount) external payable nonReentrant {
        require(totalSupply() + amount <= MAX_SUPPLY, "Sold out");
        require(amount <= maxMintPerTransaction, "Max mints per txn exceeded");
        require(msg.value >= price * amount, "Ether send is under price");
        uint256 supply = totalSupply();
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, supply + i);
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

    function withdraw() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance), "Cannot withdraw!");
    }
}