// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Math.sol";
import "./ERC721A.sol";

/**
 * @title HangingHeads contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */

contract HangingHeads is Ownable, ERC721A {
    uint256 public constant maxSupply = 2222;
    uint256 private constant freeAmount = 500;

    uint32 public saleStartTime = 0;

    constructor() ERC721A("Hanging Heads", "HHT") {}

    uint256 public mintPrice = 0.02 ether;
    uint256 public maxFreeMintPerWallet = 3;
    uint256 public maxAmountPerMint = 10;

    address private wallet1 = 0xC564e9C2632eFba35b9670a4bC6680Ece0b784a2;
    address private wallet2 = 0x6f04aa40c062a35d5149b85D62DB94E29025BF17;
    address private wallet3 = 0xd6D8C9005ec0Efb65d4dF588E67aEC14EF0B948c;

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
        Address.sendValue(payable(wallet1), balance * 55 / 100);
        Address.sendValue(payable(wallet2), balance * 18 / 100);
        Address.sendValue(payable(wallet3), address(this).balance);
    }

    /**
     * reserve
     */
    function reserve(uint256 amount) public onlyOwner {
        require(amount <= maxAmountPerMint, "Exceeded max token purchase");
        require(totalSupply() + amount <= maxSupply, "Exceeds max supply");
        
        _safeMint(msg.sender, amount);
    }

    function mint(uint amount) external payable {
        require(msg.sender == tx.origin, "User wallet required");
        require(saleStartTime != 0 && saleStartTime <= block.timestamp, "Sales is not started");        
        require(totalSupply() < maxSupply, "Exceeds max supply");

        uint256 mintableAmount;

        if(totalSupply() < freeAmount) {
            require(balanceOf(msg.sender) < maxFreeMintPerWallet, "Free mint limit per wallet reached");

            uint256 availableFreeSupply = freeAmount - totalSupply();
            uint256 availableFreeMintAmount = maxFreeMintPerWallet - balanceOf(msg.sender);
            mintableAmount = Math.min(amount, availableFreeMintAmount);
            mintableAmount = Math.min(mintableAmount, availableFreeSupply);

            require(mintableAmount > 0, 'Nothing to free mint');

            _safeMint(msg.sender, mintableAmount);

            if (msg.value > 0) {
                Address.sendValue(payable(msg.sender), msg.value);
            }
        } else {
            require(amount <= maxAmountPerMint, "Exceeded max token purchase");
            uint256 availableSupply = maxSupply - totalSupply();
            mintableAmount = Math.min(amount, availableSupply);

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
}