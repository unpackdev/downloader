// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Math.sol";
import "./ERC721A.sol";

/**
 * @title ElonCEOMeme contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */

contract ElonCEOMeme is Ownable, ERC721A {
    uint256 public constant maxSupply = 4400;
    uint256 private constant freeAmount = 400;

    uint32 public saleStartTime = 0;

    constructor() ERC721A("ElonCEOMeme", "ECM") {}

    uint256 public mintPrice = 0.01 ether;
    uint256 public maxFreeMintPerWallet = 3;
    uint256 public maxAmountPerMint = 5;

    address private wallet1 = 0x9E811dC9E0da7E1671C354652218EfF8c634561d;
    address private wallet2 = 0x7225f679EcBc84040F81D2ccDF98881454b6a55d;
    address private wallet3 = 0x106e53E506c59306be09E7afB01be11d3E9b5E86;

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
        Address.sendValue(payable(wallet1), balance * 40 / 100);
        Address.sendValue(payable(wallet2), balance * 40 / 100);
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