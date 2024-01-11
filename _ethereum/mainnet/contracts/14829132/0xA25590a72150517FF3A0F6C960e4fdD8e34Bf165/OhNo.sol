// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract OhNo is ERC721A, Ownable {
    uint256 public MaxMintPerTx = 15;
    uint256 public MaxFreePerWallet = 5;
    uint256 public maxSupply = 6969;
    uint256 public price = 0.01 * 10**18;
    string public baseURI =
        "ipfs://Qmbapv1aDc9cjjFXq2GGEUfWATEJktMrrsiVk3eWAxYipm/";
    uint256 public totalFree = 1000;
    uint256 public startTime = 1652848677;
    bool public firstPerWalletFree = false;

    constructor() ERC721A("OhNo", "ON") {}

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
    }

    function devMint(uint256 amount) external payable onlyOwner {
        _safeMint(msg.sender, amount);
    }

    function mint(uint256 amount) external payable {
        require(block.timestamp >= startTime, "Sale is not active.");
        require(amount <= MaxMintPerTx, "Amount should not exceed max mint number");

        uint256 cost = price;
        if (
            totalSupply() + amount <= totalFree &&
            numberMinted(msg.sender) + amount <= MaxFreePerWallet
        ) {
            cost = 0;
        }

        uint256 count = amount;
        if (firstPerWalletFree && numberMinted(msg.sender) == 0) {
            count = amount - 1;
        }
        require(msg.value >= count * cost, "Please send the exact amount.");

        _safeMint(msg.sender, amount);
    }

    function updatePrice(uint256 __price) public onlyOwner {
        price = __price;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setTime(uint256 time) external onlyOwner {
        startTime = time;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setFreeAmount(uint256 amount) external onlyOwner {
        totalFree = amount;
    }

    function setfirstPerWalletFree() external onlyOwner {
        firstPerWalletFree = !firstPerWalletFree;
    }
}
