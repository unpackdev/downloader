pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./RandomlyAssigned.sol";

contract X200 is ERC721, Ownable, RandomlyAssigned, ReentrancyGuard, Pausable {
  using Strings for uint256;

  event mintedId(uint256 message);

  uint256 public currentSupply = 0;
  uint256 public maxMint = 25; 
  uint256 public price = 0.04 ether; // Each token 0.04

  constructor() 
    ERC721("TheNormies", "NORMIE")
    RandomlyAssigned(10000,1)
    {
      for (uint256 a = 1; a <= 10; a++) {
            mint(1);
      }

      // Transactions are paused after deploy
      pause();
    }

  string public baseURI = "https://nft.thenormies.io/";

  function _setBaseURI(string memory _uri) public onlyOwner {
    baseURI = _uri;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
   
  function mint (uint256 _quantity)
      public
      payable
      nonReentrant
  {
      require( tokenCount() + _quantity <= totalSupply(), "YOU CAN'T MINT MORE THAN MAXIMUM SUPPLY");
      require( availableTokenCount() - _quantity >= 0, "YOU CAN'T MINT MORE THAN AVALABLE TOKEN COUNT");
      require( tx.origin == msg.sender, "CANNOT MINT THROUGH A CUSTOM CONTRACT");

      if (msg.sender != owner()) {  
        require( msg.value >= price * _quantity, "Ether sent is not correct");
        
        require( balanceOf(msg.sender) <= 20);
      }


      for (uint256 i = 1; i <= _quantity ; i++) {

        uint256 id = nextToken();
        _safeMint(msg.sender, id);

        currentSupply++;
        emit mintedId(id);

      }

  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistant token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
        : "";
  }

  function isAvailable(uint tokenId) public view returns(address){

      require( availableTokenCount() - 1 >= 0, "YOU CAN'T MINT MORE THAN AVALABLE TOKEN COUNT"); 

      address owner = ownerOf(tokenId);

      return owner;
  }
  
  function withdraw() public payable onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }

  function pause() public onlyOwner {
    _pause();
  }

  function start() public onlyOwner {
    _unpause();
  }

  function setPrice(uint256 _price) public onlyOwner() {
    price = _price;
  }

  function setMaxMint(uint256 _maxMint) public onlyOwner() {
    maxMint = _maxMint;
  }

 
}