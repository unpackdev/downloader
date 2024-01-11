// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract Bunka is ERC721A, Ownable {

    string private baseURI;

    bool private mintLive = false;

    uint256 public maxSupply = 10000;
    uint256 public free = 2500;
    uint256 public price = 0.0075 ether;
    uint256 public freePerWallet = 4;
    uint256 public freeMinted = 0;

    mapping(address => uint256) private mintedFree;

    constructor(string memory baseURI_) ERC721A("Bunka", "BUNKA") {
        setBaseURI(baseURI_);
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function mint(uint256 amount) external payable {
        require(mintLive, "Mint is not live");
        uint256 minted = totalSupply();
        require(minted + amount <= maxSupply, "Above maximum supply");
        require(msg.value >= price * amount, "Insufficient ether sent");
        _safeMint(msg.sender, amount);
    }

    function freeMint(uint256 amount) external {
        require(mintLive, "Mint is not live");
        uint256 minted = totalSupply();
        require(minted + amount <= maxSupply, "Above maximum supply");
        require(freeMinted + amount <= free, "Above maximum free supply");
        require(mintedFree[msg.sender] + amount <= freePerWallet , "Above allowed free mints");
        _safeMint(msg.sender, amount);
        mintedFree[msg.sender] += amount;
        freeMinted += amount;
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function increaseFree(uint256 free_) external onlyOwner {
        require(free_ > free, "Can't decrease free supply");
        require(free_ <= maxSupply, "Above maximum supply");
        free = free_;
    }

    function decreasePrice(uint256 price_) external onlyOwner {
        require(price_ < price, "Can't increase price");
        price = price_;
    }

    function switchMint() external onlyOwner {
        mintLive = !mintLive;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}