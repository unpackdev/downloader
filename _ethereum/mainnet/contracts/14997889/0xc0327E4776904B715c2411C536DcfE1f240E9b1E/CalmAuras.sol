// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "./Ownable.sol";


contract CalmAuras is ERC721A, Ownable {
    uint256 public constant maxBatchMintSize = 50;
    uint256 public constant mintPrice = 0.005 ether;
    uint256 public constant collectionSize = 100;

    string baseURI;

    constructor() ERC721A("Calm Abstract Linear Miladys", "CALM") {}

    function mint(uint256 quantity) external payable {
        require(totalSupply() + quantity <= collectionSize, "Cannot mint more tokens than the collection size");
        require(quantity <= maxBatchMintSize, "At most 50 can be minted at a time");
        require(msg.value >= mintPrice * quantity, "Not enough ether was sent");
        _mint(msg.sender, quantity);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Transfer Failed");
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    receive() external payable {}
    fallback() external payable {}
}
