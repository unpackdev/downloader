// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract FuckTheBearMarket is ERC721A, Ownable {
    uint256 public MaxPerTx = 30;
    uint256 public maxSupply = 6969;
    uint256 public price = 0.005 * 10**18;

    uint256 public totalFree = 6969;
    bool public mintEnabled = false;

    string public baseURI =
        "ipfs://Qme2vmpAbSRMzXT1DY3tqhp1iX3NnSGjw9NEWfybki4FeV/";

    constructor() ERC721A("FuckTheBearMarket", "FTBM") {}

    function mint(uint256 amount) external payable {
        require(totalSupply() + amount <= maxSupply, "no more");
        require(mintEnabled, "Minting is not live yet");
        require(amount <= MaxPerTx, "too many for one txn.");

        uint256 count = amount;
        if (totalSupply() + amount <= totalFree && numberMinted(msg.sender) == 0)
            count = amount - 1;

        require(msg.value >= price * count, "Ether value is incorrect.");

        _safeMint(msg.sender, amount);
    }

    function setFreeAmount(uint256 amount) external onlyOwner {
        totalFree = amount;
    }

    function flipSale() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setMaxSupply(uint256 amount) external onlyOwner {
        maxSupply = amount;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function ownerMint(uint256 amount) external payable onlyOwner {
        _safeMint(msg.sender, amount);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
    }

    function updatePrice(uint256 __price) public onlyOwner {
        price = __price;
    }
}
