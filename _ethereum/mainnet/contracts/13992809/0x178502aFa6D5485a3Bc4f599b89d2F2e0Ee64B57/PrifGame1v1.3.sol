// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract PrifGame1 is ERC721Enumerable, Ownable 
{
    using Strings for string;

    uint public MAX_TOKENS = 10000;
    uint public constant NUMBER_RESERVED_TOKENS = 100;
    uint256 public PRICE = 100000000000000000; //0.1 eth in wei 

    bool public saleIsActive = false;

    uint public reservedTokensMinted = 0;
    string private _baseTokenURI;
    string public notRevealedUri;
    bool public revealed = false;

    address payable private devguy = payable(0x0F7961EE81B7cB2B859157E9c0D7b1A1D9D35A5D);

    constructor() ERC721("Prif Game 1", "PRIF") {}

    function mintToken(uint256 amount) external payable
    {
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        require(saleIsActive, "Sale must be active to mint");
        require(amount > 0 && amount <= 10, "Max 10 NFTs per transaction");
        require(totalSupply() + amount <= MAX_TOKENS - (NUMBER_RESERVED_TOKENS - reservedTokensMinted), "Purchase would exceed max supply");
        require(msg.value >= PRICE * amount, "Not enough ETH for transaction");
        require(balanceOf(msg.sender) + amount <= 10, "Limit is 10 tokens per wallet, sale not allowed");

        for (uint i = 0; i < amount; i++) 
        {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    //case ethereum does something crazy
    function setPrice(uint256 newPrice) external onlyOwner 
    {
        PRICE = newPrice;
    }

    function setMax(uint newMax) external onlyOwner 
    {
        MAX_TOKENS = newMax;
    }

    function flipSaleState() external onlyOwner 
    {
        saleIsActive = !saleIsActive;
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

    function withdraw() external 
    {
        require(msg.sender == devguy || msg.sender == owner(), "Invalid sender");

        uint part = address(this).balance / 100 * 1;
        devguy.transfer(part);
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

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }
  
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory _tokenURI = super.tokenURI(tokenId);
    return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI, ".json")) : "";
  }
}
