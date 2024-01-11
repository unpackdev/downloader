// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract WorldOfGirls is ERC721A, Ownable {
    uint256 public MaxPerTx = 20;
    uint256 public MaxFreePerWallet = 5;
    uint256 public totalFree = 1000;
    bool public mintEnabled = false;
    uint256 public maxSupply = 4999;
    uint256 public price = 0.008 * 10**18;
    string public baseURI =
        "ipfs://QmXKHYBgBB8ucV44hnumBDGfVV6tgoDt5siBBpCZjq7bkN/";

    constructor() ERC721A("WorldOfGirls", "WOG") {}

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function ownerMint(uint256 amount) external payable onlyOwner {
        _safeMint(msg.sender, amount);
    }

    function updatePrice(uint256 __price) public onlyOwner {
        price = __price;
    }

    function mint(uint256 amount) external payable {
        require(mintEnabled, "Minting is not live yet, hold on");
        require(amount <= MaxPerTx, "too many");
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

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function flipSale() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setFreeAmount(uint256 amount) external onlyOwner {
        totalFree = amount;
    }

    function setMaxSupply(uint256 amount) external onlyOwner {
        maxSupply = amount;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
    }
}
