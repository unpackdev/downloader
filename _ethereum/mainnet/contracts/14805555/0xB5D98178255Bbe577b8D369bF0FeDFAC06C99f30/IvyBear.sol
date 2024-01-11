// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract IvyBear is ERC721A, Ownable {
    uint256 public MaxMint = 5;
    uint256 public maxSupply = 3000;
    uint256 public price = 0.005 * 10**18;
    string public baseURI =
        "ipfs://QmW672FkLfVibYA7FSY9uV41DFyrerqb4jRKUFo4reK5ob/";
    uint256 public totalFree = 1000;
    uint256 public startTime = 1652848677;

    constructor() ERC721A("IvyBear", "IB") {}

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
    }

    function devMint(uint256 amount) external payable onlyOwner {
        _safeMint(msg.sender, amount);
    }

    function mint(uint256 amount) external payable {
        require(block.timestamp >= startTime, "Sale is not active.");
        require(amount <= MaxMint, "Amount should not exceed max mint number");

        uint256 cost = price;
        if (
            totalSupply() + amount <= totalFree &&
            numberMinted(msg.sender) + amount <= MaxMint
        ) {
            cost = 0;
        }
        require(msg.value >= amount * cost, "Please send the exact amount.");

        _safeMint(msg.sender, amount);
    }

    function updatePrice(uint256 __price) public onlyOwner {
        price = __price;
    }

    function updateMaxMint(uint256 amount) public onlyOwner {
        MaxMint = amount;
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
}
