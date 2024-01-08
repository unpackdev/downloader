// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract FrostyFriends is ERC721Enumerable, Ownable 
{
    using Strings for string;

    uint public constant MAX_TOKENS = 10000;
    uint public constant NUMBER_RESERVED_TOKENS = 200;
    uint256 public constant PRICE = 50000000000000000; //0.05 eth
    uint256 public constant PRE_SALE_PRICE = 30000000000000000; //0.03 eth
    
    bool public saleIsActive = false;
    bool public preSaleIsActive = false;
    
    uint public reservedTokensMinted = 0;
    string private _baseTokenURI;

    constructor() ERC721("FrostyFriends", "FFC") {}

    function mintToken(uint256 amount) external payable
    {
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        require(saleIsActive, "Sale must be active to mint");
        require(amount > 0 && amount <= 20, "Max 20 NFTs per transaction");
        require(totalSupply() + amount <= MAX_TOKENS - (NUMBER_RESERVED_TOKENS - reservedTokensMinted), "Purchase would exceed max supply");
        require(msg.value >= PRICE * amount, "Not enough ETH for transaction");

        for (uint i = 0; i < amount; i++) 
        {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }
    
    function mintTokenPreSale(uint256 amount) external payable
    {
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        require(preSaleIsActive, "Pre-sale must be active to mint");
        require(amount > 0 && amount <= 3, "Max 3 NFTs per transaction");
        require(totalSupply() + amount <= MAX_TOKENS - (NUMBER_RESERVED_TOKENS - reservedTokensMinted), "Purchase would exceed max supply");
        require(msg.value >= PRE_SALE_PRICE * amount, "Not enough ETH for transaction");
        require(balanceOf(msg.sender) + amount <= 3, "Limit is 3 tokens per wallet, sale not allowed");

        for (uint i = 0; i < amount; i++) 
        {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function flipSaleState() external onlyOwner 
    {
        preSaleIsActive = false;
        saleIsActive = !saleIsActive;
    }
    
    function flipPreSaleState() external onlyOwner 
    {
        preSaleIsActive = !preSaleIsActive;
    }

    function mintReservedTokens(address to, uint256 amount) external onlyOwner 
    {
        require(reservedTokensMinted + amount <= NUMBER_RESERVED_TOKENS, "This amount is more than max allowed");

        for (uint i = 0; i < amount; i++) 
        {
            _safeMint(to, totalSupply() + 1);
            reservedTokensMinted++;
        }
    }

    function withdraw() external onlyOwner
    {
        payable(owner()).transfer(address(this).balance);
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId) public view
        override(ERC721Enumerable) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    ////
    //URI management part
    ////
    
    function _setBaseURI(string memory baseURI) internal virtual {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
    
    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }
  
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        string memory _tokenURI = super.tokenURI(tokenId);
        return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI, ".json")) : "";
    }
}
