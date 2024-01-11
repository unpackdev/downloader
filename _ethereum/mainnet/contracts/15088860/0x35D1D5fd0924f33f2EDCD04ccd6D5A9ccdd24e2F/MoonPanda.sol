// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract MoonPanda is ERC721A, Ownable {
    uint256 public MaxFreePerWallet = 2;
    bool public mintEnabled = false;
    uint256 public maxSupply = 4444;
    uint256 public price = 0.004 ether;
    string public baseURI = "ipfs://QmRnEmPA2kccjkYaa15mkmLJ9XNP4WRDNgJvma7WdmMSDA/";

    constructor() ERC721A("MoonPanda", "MOONPANDA") {}

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
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

    function mint(uint256 amount) external payable {
        require(mintEnabled, "hold on");
        require(totalSupply() + amount <= maxSupply, "sold out");

        uint256 count = amount;
        if (numberMinted(msg.sender) < MaxFreePerWallet) {
            count = amount - (MaxFreePerWallet - numberMinted(msg.sender));
        }
        require(msg.value >= count * price, "Please send the exact amount.");

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

    function setMaxSupply(uint256 amount) external onlyOwner {
        maxSupply = amount;
    }

    function devMint(uint256 amount) external payable onlyOwner {
        _safeMint(msg.sender, amount);
    }
}
