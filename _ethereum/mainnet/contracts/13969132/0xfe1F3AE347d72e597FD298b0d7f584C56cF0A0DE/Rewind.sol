// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract Rewind is ERC721, Ownable {    
    constructor() ERC721("NFT Rewind 2021", "REWIND") {}

    uint256 public constant MINT_PRICE = .02 ether;

    uint256 public MAX_TOKENS = 5000;
    uint256 public MAX_FREE = 3000;
    uint256 public minted = 0;
    uint256 public free = 0;

    bool public onSale = false;

    string public baseTokenURI = "ipfs://Qmeq7TZtS7cKBN1rSvvQzBjguXtK9rGKtWJqSgVUy8DiSf/";

    function mint(uint256 amount) external payable {
        require(onSale, "Minting not live");
        require(minted + amount <= MAX_TOKENS, "All tokens minted");
        require(amount > 0 && amount <= 10, "Invalid mint amount");
        require(amount * MINT_PRICE == msg.value, "Invalid payment amount");
        
        for (uint i = 0; i < amount; i++) {
            minted++;
            _mint(msg.sender, minted);
        }
    }

    function mintFree(uint256 amount) external {
        require(onSale, "Minting not live");
        require(minted + amount <= MAX_TOKENS, "All tokens minted");
        require(free + amount <= MAX_FREE, "All free tokens minted");
        require(amount > 0 && amount <= 5, "Invalid mint amount");
        
        free = free + amount;

        for (uint i = 0; i < amount; i++) {
            minted++;
            _mint(msg.sender, minted);
        }
    }

    function changeOnSale() external onlyOwner(){
        onSale = !onSale;
    }

    function setBaseURI(string calldata _uri) external onlyOwner(){
        baseTokenURI = _uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    //Utilities
    function withdrawAll() external onlyOwner() {
        require(payable(msg.sender).send(address(this).balance));
    }
}