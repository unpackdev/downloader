// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract MiniAzteca is Ownable, ERC721A, ReentrancyGuard {

    uint256 public immutable MAX_SUPPLY = 5000;

    bool public saleActive = false;

    uint256 public maxMintPerTxn = 1;

    string public baseURI;

    constructor(string memory name_, string memory symbol_) ERC721A(name_, symbol_) {}

    modifier supplyCheck(uint256 amount) {
        require(totalSupply() + amount <= MAX_SUPPLY, "Txn exceeds the supply.");
        _;
    }

    modifier saleIsActive() {
        require(saleActive, "Sale not active, sir.");
        _;
    }

    modifier maxMintCheck(uint256 amount) {
        require(amount <= maxMintPerTxn, "Exceeds txn limit.");
        _;
    }

    function freeMint(uint256 amount)
        public
        nonReentrant
        saleIsActive
        maxMintCheck(amount)
        supplyCheck(amount)
    {
        _safeMint(msg.sender, amount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseUri(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setMaxMintPerTxn(uint256 amount) external onlyOwner {
        maxMintPerTxn = amount;
    }

    function toggleSale() external onlyOwner {
        saleActive = !saleActive;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}