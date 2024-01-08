//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Strings.sol";


contract NiftyDJ is Ownable, ERC721Enumerable, ERC721Burnable, ERC721URIStorage  {
  using Strings for uint256;

  uint256 public MAX_SUPPLY;
  uint256 public price;
  bool public salePaused; 

  string private _baseTokenURI;
  string private _baseTokenExtension;

  constructor(uint256 maxSupply, uint256 initialPrice, string memory baseURI) public ERC721("Nifty DJs", "NFDJ") {
    salePaused = true;
    MAX_SUPPLY = maxSupply;
    price = initialPrice;
    _baseTokenExtension = '.json';
    _baseTokenURI = baseURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  /************ OWNER FUNCTIONS ************/

  function changeBaseURI(string calldata baseURI) public onlyOwner {
    _baseTokenURI = baseURI;
  }
  
  function withdraw() public onlyOwner {
    payable(0x78160a087f0714Aa6D342760eF9A132AfeC42476).transfer((address(this).balance*28)/100);
    payable(0xC1b856b810C18D281f658C3a29b3890868DD70DE).transfer(address(this).balance);
  }

  function setPrice(uint256 newPrice) public onlyOwner {
    price = newPrice;
  }

  function beginSale() public onlyOwner {
    salePaused = false;
  }

  function pauseSale() public onlyOwner {
    salePaused = true;
  }

  function ownerMint(uint256 quantity) public onlyOwner {
    require(totalSupply() + quantity <= MAX_SUPPLY, "MINT:MAX SUPPLY REACHED");
    for(uint i = 0; i < quantity; i++) {
      _mint(owner(), totalSupply());
    }
  }
 
  function setTokenExtension(string memory extension) public onlyOwner {
    _baseTokenExtension = extension;
  }      

  function mint(uint256 quantity) public payable {
    require(totalSupply() + quantity <= MAX_SUPPLY, "MINT:MAX SUPPLY REACHED");
    require(msg.value == price * quantity, "MINT:MSG.VALUE INCORRECT");
    require(quantity <= 50, "MINT:MSG.VALUE INCORRECT");    
    require(!salePaused, "MINT:SALE PAUSED");
    for (uint256 i = 0; i < quantity; i++) {
      _safeMint(msg.sender, totalSupply());
    }
  }

  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    return string(abi.encodePacked(_baseURI(), tokenId.toString(), _baseTokenExtension));
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    return super._burn(tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
      public
      view
      virtual
      override(ERC721, ERC721Enumerable)
      returns (bool)
  {
      return super.supportsInterface(interfaceId);
  }

  function _beforeTokenTransfer(
      address from,
      address to,
      uint256 tokenId
  ) internal virtual override(ERC721, ERC721Enumerable) {
      super._beforeTokenTransfer(from, to, tokenId);
  }
}
