// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract Moonkeys is ERC721A, Ownable {
    bool public onSale = false;
    uint256 public MaxMintPerTx = 50;
    uint256 public MaxFreePerWallet = 10;
    uint256 public maxSupply = 8888;
    uint256 public price = 0.004 * 10**18;
    string public baseURI =
        "ipfs://QmVygEbZQLD8tqo1t7NaieEif2ZA3v11nESsZ7SPq4PeWX/";

    constructor() ERC721A("Moonkeys", "MOONKEYS") {}

    function flipSale() external onlyOwner {
        onSale = !onSale;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
    }

    function devMint(uint256 amount) external payable onlyOwner {
        _safeMint(msg.sender, amount);
    }

    function mint(uint256 amount) external payable {
        require(onSale, "hold on, moonkeys");
        require(amount <= MaxMintPerTx, "too many moonkeys for a signle txn");
        require(totalSupply() + amount <= maxSupply, "no more moonkeys");

        uint256 cost = price;
        if (numberMinted(msg.sender) + amount <= MaxFreePerWallet) {
            cost = 0;
        }
        require(msg.value >= amount * cost, "Please send the exact amount.");

        _safeMint(msg.sender, amount);
    }

    function updatePrice(uint256 __price) public onlyOwner {
        price = __price;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setMaxFreePerWallet(uint256 amount) external onlyOwner {
        MaxFreePerWallet = amount;
    }
}
