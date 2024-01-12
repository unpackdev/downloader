// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract Booble is ERC721A, Ownable {
    uint256 public MaxPerTx = 20;
    uint256 public MaxFreePerWallet = 1;
    bool public saleStarted = false;
    uint256 public maxSupply = 6969;
    uint256 public price = 0.006 ether;
    string public baseURI =
        "ipfs://QmZEs8R7JgeCeR9drLhFnaSvM7XbdKMNoGEhgqoh7rG1zB/";

    constructor() ERC721A("Booble", "BOOBLE") {}

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function ownerMint(uint256 amount) external payable onlyOwner {
        _safeMint(msg.sender, amount);
    }

    function updatePrice(uint256 __price) public onlyOwner {
        price = __price;
    }

    function publicSale(uint256 amount) external payable {
        require(saleStarted, "Sale is not active.");
        require(amount <= MaxPerTx, "Amount should not exceed max mint number!");
        require(totalSupply() + amount <= maxSupply, "Amount should not exceed max supply.");

        uint256 count = amount;
        if (numberMinted(msg.sender) < MaxFreePerWallet) {
            if (numberMinted(msg.sender) + amount <= MaxFreePerWallet)
                count = 0;
            else count = numberMinted(msg.sender) + amount - MaxFreePerWallet;
        }

        require(msg.value >= count * price, "Eth value is not enough");

        _safeMint(msg.sender, amount);
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
