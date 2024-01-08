// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./Ownable.sol";

contract EvilElvesClub is ERC721, ERC721Enumerable, Ownable 
{
    using Strings for string;

    uint public constant MAX_TOKENS = 5555;
    uint public constant NUMBER_RESERVED_TOKENS = 50;
    uint256 public constant PRICE = 55500000000000000;

    bool public saleIsActive = false;
    bool public preSaleIsActive = false;

    uint public reservedTokensMinted = 0;
    uint public supply = 0;
    string private _baseTokenURI;

    address payable private recipient1 = payable(0x0F7961EE81B7cB2B859157E9c0D7b1A1D9D35A5D);

    constructor() ERC721("Evil Elves Club", "EEC") {}

    function mintToken(uint256 amount) external payable
    {
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        require(saleIsActive, "Sale must be active to mint");
        require(supply + amount <= MAX_TOKENS - (NUMBER_RESERVED_TOKENS - reservedTokensMinted), "Purchase would exceed max supply");

        require(msg.value >= PRICE * amount, "Not enough ETH for transaction");
        require(balanceOf(msg.sender) + amount <= 10, "Limit is 10 tokens per wallet, sale not allowed");

        if (amount > 4) amount++; //one extra when buying 5 or more
        if (amount > 9) amount++; //one more extra when buying 10 or more

        for (uint i = 0; i < amount; i++) 
        {
            _safeMint(msg.sender, supply);
            supply++;
        }
    }
    
    function mintTokenPreSale(uint256 amount) external payable
    {
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        require(preSaleIsActive, "Pre-sale must be active to mint");
        require(supply + amount <= MAX_TOKENS - (NUMBER_RESERVED_TOKENS - reservedTokensMinted), "Purchase would exceed max supply");
        
        require(msg.value >= PRICE * amount, "Not enough ETH for transaction");
        require(balanceOf(msg.sender) + amount <= 5, "Limit is 5 tokens per wallet on pre-sale, sale not allowed");

        if (amount == 5) amount++; //one extra when buying 5 
        
        for (uint i = 0; i < amount; i++) 
        {
            _safeMint(msg.sender, supply);
            supply++;
        }
    }

    function flipSaleState() external onlyOwner 
    {
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
            _safeMint(to, supply);
            supply++;
            reservedTokensMinted++;
        }
    }

    function withdraw() external 
    {
        require(msg.sender == recipient1 || msg.sender == owner(), "Invalid sender");

        uint part = address(this).balance / 100 * 7;
        recipient1.transfer(part);
        payable(owner()).transfer(address(this).balance);
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId) public view
        override(ERC721, ERC721Enumerable) returns (bool)
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