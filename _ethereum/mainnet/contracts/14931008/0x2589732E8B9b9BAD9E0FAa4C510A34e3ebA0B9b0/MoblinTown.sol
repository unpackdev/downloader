// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Math.sol";
import "./ERC721A.sol";

/**
 * @title MoblinTown contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */

contract MoblinTown is Ownable, ERC721A {
    uint256 public constant maxSupply = 3333;
    uint256 private constant freeAmount = 333;

    uint32 public saleStartTime = 0;

    constructor() ERC721A("Moblin Town", "MTT") {}

    uint256 public mintPrice = 0.01 ether;
    uint256 public maxFreeMintPerWallet = 1;
    uint256 public maxMintPerWallet = 5;
    uint256 public maxAmountPerMint = 5;
    uint256 private totalFreeMinted;

    address private wallet1 = 0x801FF550dBfFb0012894F5Ab4664623d4CDAc026;
    address private wallet2 = 0x91B238f1b63873e8D887dA7a61De57314c001673;

    function setSaleStartTime(uint32 newTime) public onlyOwner {
        saleStartTime = newTime;
    }

    function setMintPrice(uint256 newMintPrice) external onlyOwner {
        mintPrice = newMintPrice;
    }

    function setMaxAmountPerMint(uint256 newMaxAmountPerMint) external onlyOwner {
        maxAmountPerMint = newMaxAmountPerMint;
    }

    function setMaxFreeMintPerWallet(uint256 newMaxFreeMintPerWallet) external onlyOwner {
        maxFreeMintPerWallet = newMaxFreeMintPerWallet;
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
        Address.sendValue(payable(wallet1), balance * 65 / 100);
        Address.sendValue(payable(wallet2), address(this).balance);
    }

    /**
     * reserve
     */
    function reserve(uint256 amount, address sender) public onlyOwner {
        require(totalSupply() + amount <= maxSupply, "Exceeds max supply");
        
        _safeMint(sender, amount);
    }

    function mint(uint amount) external payable {
        require(msg.sender == tx.origin, "User wallet required");
        require(balanceOf(msg.sender) < maxMintPerWallet, "Mint limit per wallet reached");
        require(saleStartTime != 0 && saleStartTime <= block.timestamp, "Sales is not started");        
        require(totalSupply() < maxSupply, "Exceeds max supply");

        uint256 mintableAmount;
        uint256 feeMintableAmount;
        uint256 currentMintedAmount = balanceOf(msg.sender);

        if (currentMintedAmount < maxFreeMintPerWallet && totalFreeMinted < freeAmount)
            feeMintableAmount = Math.min(maxFreeMintPerWallet - currentMintedAmount, freeAmount - totalFreeMinted);

        if(feeMintableAmount > 0) {
            totalFreeMinted = totalFreeMinted + feeMintableAmount;
        }
        
        mintableAmount = Math.min(amount, maxMintPerWallet - currentMintedAmount);
        mintableAmount = Math.min(mintableAmount, maxSupply - totalSupply());
        if(mintableAmount > 0) {
            uint256 totalMintCost = (mintableAmount - feeMintableAmount) * mintPrice;
            require(msg.value >= totalMintCost, "Not enough ETH sent; check price!");

            _safeMint(msg.sender, mintableAmount);

            // Refund unused fund
            uint256 changes = msg.value - totalMintCost;
            if (changes != 0) {
                Address.sendValue(payable(msg.sender), changes);
            }
        }
    }
}