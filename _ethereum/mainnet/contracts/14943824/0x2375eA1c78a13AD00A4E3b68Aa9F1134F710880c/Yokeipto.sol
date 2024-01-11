// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract Yokeipto is ERC721A, Ownable {
    string public baseURI =
        "ipfs://QmeqnVC16gWk6nCksjsNZUDZh9DES5vovgYGpUNJZ9epPx/";
    uint256 public maxSupply = 4444;
    uint256 public price = 0.004 ether;
    uint256 public MaxPerTx = 30;
    uint256 public MaxFreePerWallet = 3;
    uint256 public totalFree = 2000;
    bool public mintStarted = false;

    constructor() ERC721A("Yokeipto", "YOK") {}

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function startSale() external onlyOwner {
        mintStarted = !mintStarted;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function ownerMint(uint256 amount) external payable onlyOwner {
        _safeMint(msg.sender, amount);
    }

    function mint(uint256 amount) external payable {
        require(mintStarted, "please hold on");
        require(amount <= MaxPerTx, "too many");
        require(totalSupply() + amount <= maxSupply, "no more");

        uint256 cost = price;
        if (
            totalSupply() + amount <= totalFree &&
            numberMinted(msg.sender) + amount <= MaxFreePerWallet
        ) {
            cost = 0;
        }
        require(msg.value >= amount * cost, "more eth please");

        _safeMint(msg.sender, amount);
    }

    function setFreeAmount(uint256 amount) external onlyOwner {
        totalFree = amount;
    }

    function setMaxSupply(uint256 amount) external onlyOwner {
        maxSupply = amount;
    }

    function setMaxFreePerWallet(uint256 amount) external onlyOwner {
        MaxFreePerWallet = amount;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to send");
    }

    function updatePrice(uint256 __price) public onlyOwner {
        price = __price;
    }
}
