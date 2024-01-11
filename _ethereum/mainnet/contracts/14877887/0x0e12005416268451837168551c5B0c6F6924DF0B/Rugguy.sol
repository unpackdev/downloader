// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract Rugguy is ERC721A, Ownable {
    uint256 public MaxPerTx = 25;
    uint256 public maxSupply = 6969;
    uint256 public MaxFreePerWallet = 5;
    uint256 public totalFree = 2000;
    bool public mintEnabled = false;
    uint256 public price = 0.005 * 10**18;
    string public baseURI =
        "ipfs://QmY7Aafrp8k95kGUoXbXovq3qTpZAiZqRozATC2sSf4gfD/";

    constructor() ERC721A("Rugguy", "RG") {}

    function flipSale() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setFreeAmount(uint256 amount) external onlyOwner {
        totalFree = amount;
    }

    function mint(uint256 amount) external payable {
        require(amount <= MaxPerTx, "too many!");
        require(totalSupply() + amount <= maxSupply, "sold out!");
        require(mintEnabled, "hold on!");

        uint256 cost = price;
        if (
            totalSupply() + amount <= totalFree &&
            numberMinted(msg.sender) + amount <= MaxFreePerWallet
        ) {
            cost = 0;
        }
        require(msg.value >= amount * cost, "more money!");

        _safeMint(msg.sender, amount);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setMaxSupply(uint256 amount) external onlyOwner {
        maxSupply = amount;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function ownerMint(uint256 amount) external payable onlyOwner {
        _safeMint(msg.sender, amount);
    }

    function updatePrice(uint256 __price) public onlyOwner {
        price = __price;
    }
}
