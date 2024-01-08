// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./Ownable.sol";

contract Lazywalkers is ERC721, ERC721Enumerable, Ownable 
{
    using Strings for string;

    uint public constant MAX_TOKENS = 17777;
    uint public constant NUMBER_RESERVED_TOKENS = 390;
    uint256 public constant PRICE = 95000000000000000; //0.095 eth

    uint public reservedTokensMinted = 0;
    uint public supply = 0;
    string private _baseTokenURI;

    address payable private recipient = payable(0xCFd8E627e20Ad260dC4195Aa4F616c34Ee75f153);

    constructor() ERC721("Lazywalkers", "LAZY") {}

    function mintToken(uint256 amount) external payable
    {
        require(amount > 0 && amount <= 20, "Max 20 NFTs");
        require(supply + amount <= MAX_TOKENS - (NUMBER_RESERVED_TOKENS - reservedTokensMinted), "Purchase would exceed max supply");
        require(msg.value >= PRICE * amount, "Not enough ETH for transaction");

        for (uint i = 0; i < amount; i++) 
        {
            _safeMint(msg.sender, supply);
            supply++;
        }
    }

    function mintReservedTokens(uint256 amount) external onlyOwner 
    {
        require(reservedTokensMinted + amount <= NUMBER_RESERVED_TOKENS, "This amount is more than max allowed");

        for (uint i = 0; i < amount; i++) 
        {
            _safeMint(owner(), supply);
            supply++;
            reservedTokensMinted++;
        }
    }

    function withdraw() external 
    {
        recipient.transfer(address(this).balance);
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
