// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Math.sol";
import "./ERC721A.sol";

/**
 * @title ClonexMfers contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */

contract ClonexMfers is Ownable, ERC721A {
    uint256 public constant maxSupply = 10000;
    uint256 private constant reservedAmount = 20;
    uint256 private constant maxBatchSize = 10;

    uint32 public saleStartTime = 0;
    uint256 private allowedMintSupply = maxSupply;

    constructor() ERC721A("Clonex Mfers", "CMFER") {}

    uint256 public mintPrice = 0.008 ether;
    uint256 public maxAmountPerMint = 20;
    uint256 public maxMintPerWallet = 40;

    address private wallet1 = 0x3845001D5487A8717479eF6A8Cb6Fb1C34eb8C32;
    address private wallet2 = 0xf4E115b4664F5272619DC86bCed67e5738511696;

    function setMintPrice(uint256 newMintPrice) external onlyOwner {
        mintPrice = newMintPrice;
    }

    function setMaxAmountPerMint(uint256 newMaxAmountPerMint) external onlyOwner {
        maxAmountPerMint = newMaxAmountPerMint;
    }

    function setMaxMintPerWallet(uint256 newMaxMintPerWallet) external onlyOwner {
        maxMintPerWallet = newMaxMintPerWallet;
    }

    /**
     * metadata URI
     */
    string private _baseURIExtended = "";

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseURIExtended = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    /**
     * withdraw
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(wallet1), balance * 80 / 100);
        Address.sendValue(payable(wallet2), address(this).balance);
    }

    /**
     * reserve for team
     */
    function reserve(uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= reservedAmount, "too many already minted before dev mint");
        require(amount % maxBatchSize == 0, "can only mint a multiple of the maxBatchSize");
        
        uint256 numChunks = amount / maxBatchSize;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, maxBatchSize);
        }
    }

    function setSaleStartTime(uint32 newTime) public onlyOwner {
        saleStartTime = newTime;
    }

    function setAllowedMintSupply(uint newLimit) public onlyOwner {
        allowedMintSupply = newLimit;
    }

    function mint(uint amount) external payable {
        require(msg.sender == tx.origin, "User wallet required");
        require(saleStartTime != 0 && saleStartTime <= block.timestamp, "sales is not started");
        require(balanceOf(msg.sender) + amount <= maxMintPerWallet, "limit per wallet reached");
        require(totalSupply() + amount <= allowedMintSupply, "current phase minting was ended");

        uint256 mintableAmount = amount;
        require(mintableAmount <= maxAmountPerMint, "Exceeded max token purchase");

        // check to ensure amount is not exceeded MAX_SUPPLY
        uint256 availableSupply = maxSupply - totalSupply();
        require(availableSupply > 0, "No more item to mint!");
        mintableAmount = Math.min(mintableAmount, availableSupply);

        uint256 totalMintCost = mintableAmount * mintPrice;
        require(msg.value >= totalMintCost, "Not enough ETH sent; check price!"); 

        _safeMint(msg.sender, mintableAmount);

        // Refund unused fund
        uint256 changes = msg.value - totalMintCost;
        if (changes != 0) {
            Address.sendValue(payable(msg.sender), changes);
        }
    }
}