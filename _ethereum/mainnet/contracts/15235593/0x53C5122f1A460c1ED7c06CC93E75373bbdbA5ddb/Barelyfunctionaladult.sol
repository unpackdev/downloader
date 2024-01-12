// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract Barelyfunctionaladult is ERC721A, Ownable {
    uint256 public MaxFreePerWallet = 2;
    bool public saleStarted = false;
    uint256 public maxSupply = 5555;
    uint256 public price = 0.01 ether;
    string public baseURI = "ipfs://QmfEzNVETLFe1QZnNaRgd9iMBrv9LxaZMeaXZCxNEGxuC7/";
    uint256 public totalFree = 2000;

    constructor() ERC721A("Barelyfunctionaladult", "BFA") {}

    function mint(uint256 amount) external payable {
        require(saleStarted, "Sale is not started yet.");
        require(
            totalSupply() + amount <= maxSupply,
            "sold out."
        );

        uint256 cost = price;
        if (
            totalSupply() + amount <= totalFree &&
            numberMinted(msg.sender) + amount <= MaxFreePerWallet
        ) {
            cost = 0;
        }

        require(msg.value >= amount * cost, "Eth value is not enough");

        _safeMint(msg.sender, amount);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function devMint(uint256 amount) external payable onlyOwner {
        _safeMint(msg.sender, amount);
    }

    function updatePrice(uint256 __price) public onlyOwner {
        price = __price;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function toggleSale() external onlyOwner {
        saleStarted = !saleStarted;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setMaxSupply(uint256 amount) external onlyOwner {
        maxSupply = amount;
    }

    function setMaxFreePerWallet(uint256 amount) external onlyOwner {
        MaxFreePerWallet = amount;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
    }
}
