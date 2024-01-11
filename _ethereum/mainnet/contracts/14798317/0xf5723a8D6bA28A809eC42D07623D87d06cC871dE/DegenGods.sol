// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract DegenGods is ERC721A, Ownable, ReentrancyGuard {
    string public baseURI;
    uint256 public price = 0.01 ether;
    uint256 public maxPerTx = 25;
    uint256 public maxSupply = 10000;
    bool public mintEnabled;

    constructor() ERC721A("DegenGods", "GOD") {}

    function mint(uint256 amount) external payable {
        require(mintEnabled, "Minting is not live yet!");
        require(msg.sender == tx.origin, "Machines haven't ascended yet.");
        require(msg.value == amount * price, "Please send the exact amount.");
        require(amount < maxPerTx + 1, "Max per TX reached.");
        require((totalSupply() + amount) < maxSupply + 1, "No more gods.");

        _safeMint(msg.sender, amount);
    }

    function toggleMinting() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}
