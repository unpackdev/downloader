// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract RRKODAS is ERC721A, Ownable, ReentrancyGuard {

    string public baseURI;

    uint256 public price = 0.005 ether;
    uint256 public maxPerTx = 10;
    uint256 public maxPerWallet = 10;
    uint256 public maxSupply = 5402;
    uint256 public maxFree = 1000;

    bool public publicSaleIsLive;

    constructor() ERC721A("RR/KODAS", "RR/K")  {}

    function mint(uint256 amount) external payable nonReentrant {
        uint256 cost = price;

        if (totalSupply() + amount <= maxFree) {
            cost = 0;
        }
        require(msg.sender == tx.origin, "You can't mint from a contract.");
        require(msg.value == amount * cost, "Please send the exact amount in order to mint.");
        require(totalSupply() + amount <= maxSupply, "Better Luck next time, Sold out.");
        require(publicSaleIsLive, "Public sale is not live yet.");
        require(numberMinted(msg.sender) + amount <= maxPerWallet, "You have exceeded the mint limit per wallet.");
        require(amount <= maxPerTx, "You have exceeded the mint limit per transaction.");

        _mint(msg.sender, amount);
    }

    function ownerMint(uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= maxSupply, "Can't mint");

        _safeMint(msg.sender, amount);
    }

    function toggleSaleState() external onlyOwner {
        publicSaleIsLive = !publicSaleIsLive;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setPrice(uint256 price_) external onlyOwner {
      price = price_;
    }

    function setMaxPerTx(uint256 maxPerTx_) external onlyOwner {
      maxPerTx = maxPerTx_;
    } 

    function setMaxPerWallet(uint256 maxPerWallet_) external onlyOwner {
      maxPerWallet = maxPerWallet_;
    }

    function setmaxSupply(uint256 maxSupply_) external onlyOwner {
      maxSupply = maxSupply_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}