// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol"; 

contract RockTheCulture is ERC721A, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter; 

  Counters.Counter private supply;

    string URI = "https://gateway.pinata.cloud/ipfs/QmcLSgAPJ47WD7AYi7KQL2kzASZHmAXTUeWzP2a2HnL4dP/";
    uint256 public constant MAX_SUPPLY = 6969;
    uint256 public constant FREE_AMOUNT = 1969;
    uint256 public constant MAX_PER_TX = 10;
    uint256 public constant MAX_PER_TX_PUBLIC = 20;
    uint256 public MINT_PRICE = 0.001 ether;
    
    uint256 public CLAIMED_SUPPLY;

    bool public IS_SALE_ACTIVE = false;

  constructor() ERC721A("RockTheCulture", "RTC") {} 

  function ownerMint(uint256 quantity) external payable {
      require(CLAIMED_SUPPLY + quantity <= MAX_SUPPLY, "Excedes max supply.");
      require(msg.sender == owner(), "You're not allowed for owner mint");
      require(quantity <= MAX_PER_TX_PUBLIC, "Exceeds max per transaction."); 
      _mint(msg.sender, quantity); 
      CLAIMED_SUPPLY += quantity;
  } 

   function claim(uint256 quantity) external payable {
        require(CLAIMED_SUPPLY + quantity <= MAX_SUPPLY, "Excedes max supply.");
        require(IS_SALE_ACTIVE,"Sale not active"); 

        if (CLAIMED_SUPPLY >= FREE_AMOUNT) {
          require( MINT_PRICE * quantity <= msg.value, "Ether value sent is not correct");
          require(quantity <= MAX_PER_TX_PUBLIC, "Exceeds max per transaction.");
         _mint(msg.sender, quantity);   
         CLAIMED_SUPPLY += quantity;
        }
        else{
        require(quantity <= MAX_PER_TX, "Exceeds max per transaction."); 
         _mint(msg.sender, quantity);   
         CLAIMED_SUPPLY += quantity;
        }
 
    } 

  function startSale() public onlyOwner {
      IS_SALE_ACTIVE = !IS_SALE_ACTIVE;
    }
 

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= MAX_SUPPLY) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

 function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    ); 
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
        : "";
  }


  function setMINT_PRICE(uint256 _MINT_PRICE) public onlyOwner {
    MINT_PRICE = _MINT_PRICE;
  }

  
  function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
 

  function setURI(string memory _URI) public onlyOwner {
      URI = _URI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return URI;
  }
}   