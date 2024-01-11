// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract TheSkullWarriors is ERC721A, Ownable {
    uint256 public MaxPerTx = 30;
    uint256 public MaxFreePerWallet = 3;
    uint256 public totalFree = 2000;
    bool public mintEnabled = false;
    uint256 public maxSupply = 6969;
    uint256 public price = 0.008 ether;
    string public baseURI = "ipfs://QmZSTVRBv47hHu51oNgnHcVQ3iLeCgjwaNLSj2A158CTax/";

    constructor() ERC721A("TheSkullWarriors", "TSW") {}

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function toggleSale() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setFreeAmount(uint256 amount) external onlyOwner {
        totalFree = amount;
    }

    function mint(uint256 amount) external payable {
        require(mintEnabled, "Sale is not active");
        require(amount <= MaxPerTx, "too many for one txn");
        require(totalSupply() + amount <= maxSupply, "sold out");

        uint256 cost = price;
        if (
            totalSupply() + amount <= totalFree &&
            numberMinted(msg.sender) + amount <= MaxFreePerWallet
        ) {
            cost = 0;
        }

        require(msg.value >= amount * cost, "Please send the exact amount.");

        _safeMint(msg.sender, amount);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function ownerMint(uint256 amount) external payable onlyOwner {
        _safeMint(msg.sender, amount);
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

    function updatePrice(uint256 __price) public onlyOwner {
        price = __price;
    }
}
