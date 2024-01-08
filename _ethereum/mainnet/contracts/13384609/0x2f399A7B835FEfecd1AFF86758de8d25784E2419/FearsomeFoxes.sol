// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./Ownable.sol";

contract FearsomeFoxes is ERC721, ERC721Enumerable, Ownable 
{
    using Strings for string;

    bool public saleIsActive = false;

    uint public nextId = 1;
    string private _baseTokenURI;
    
    uint[] public mintedTokenTypes;
    uint[] public typePrice;
    
    uint public limitPerWallet = 1;

    address payable private recipient1 = payable(0x0F7961EE81B7cB2B859157E9c0D7b1A1D9D35A5D);
    address payable private recipient2 = payable(0xE957E3c129002504e0E0Ae9d4aF6296722A063b4);

    constructor() ERC721("Fearsome Foxes", "FF") 
    {
        mintedTokenTypes.push(0);
    }

    function mintToken(uint256 amount, uint tokenType) external payable
    {
        require(saleIsActive, "Sale must be active to mint");
        require(amount > 0 && amount <= 10, "Max 10 NFTs per transaction");
        require(tokenType >= 0 && tokenType < typePrice.length, "This type doesn't exist");
        require(msg.value >= typePrice[tokenType] * amount, "Not enough ETH for transaction");
        require(balanceOf(msg.sender) + amount <= limitPerWallet, "Limit per wallet achieved, sale not allowed");
        
        for (uint i = 0; i < amount; i++) 
        {
            _safeMint(msg.sender, nextId);
            nextId++;
            mintedTokenTypes.push(tokenType);
        }
    }
    
    function airdropToken(address to, uint256 amount, uint tokenType) external onlyOwner 
    {
        require(tokenType >= 0 && tokenType < typePrice.length, "This type doesn't exist");
        
        for (uint i = 0; i < amount; i++) 
        {
            _safeMint(to, nextId);
            nextId++;
            mintedTokenTypes.push(tokenType);
        }
    }
    
    function setPrice(uint256 newPrice, uint tokenType) external onlyOwner
    {
        require(tokenType >= 0 && tokenType <= typePrice.length, "You can add only one type");
        if (tokenType == typePrice.length)
            typePrice.push(newPrice);
        else
            typePrice[tokenType] = newPrice;
    }
    
    function setLimitPerWallet(uint newLimit) external onlyOwner
    {
        limitPerWallet = newLimit;
    }
    
    function howManyTypes() external view returns (uint nTypes)
    {
        return typePrice.length;
    }

    function flipSaleState() external onlyOwner 
    {
        saleIsActive = !saleIsActive;
    }

    function withdraw() external 
    {
        require(msg.sender == recipient1 || msg.sender == recipient2 || msg.sender == owner(), "Invalid sender");

        uint recipient1Part = address(this).balance / 100 * 6;
        uint recipient2Part = address(this).balance / 100 * 1;
        recipient1.transfer(recipient1Part);
        recipient2.transfer(recipient2Part);
        payable(owner()).transfer(address(this).balance);
    }
    
    function supportsInterface(bytes4 interfaceId) public view
        override(ERC721, ERC721Enumerable) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    function tokensOfOwner(address _owner) external view returns(uint256[] memory) 
    {
      	uint256 tokenCount = balanceOf(_owner);
      	if (tokenCount == 0) 
      	{
      		return new uint256[](0);
      	} 
      	else 
      	{
      		uint256[] memory result = new uint256[](tokenCount);
      		uint256 index;
      		for (index = 0; index < tokenCount; index++) 
      		{
      			result[index] = tokenOfOwnerByIndex(_owner, index);
      		}
      		return result;
      	}
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function _setBaseURI(string memory baseURI) internal virtual 
    {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) 
    {
        return _baseTokenURI;
    }
    
    function setBaseURI(string memory baseURI) external onlyOwner 
    {
        _setBaseURI(baseURI);
    }
  
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) 
    {
        string memory _tokenURI = super.tokenURI(tokenId);
        return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI, ".json")) : "";
    }
}
