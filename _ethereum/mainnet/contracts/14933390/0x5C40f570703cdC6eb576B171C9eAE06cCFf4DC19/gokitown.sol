  // SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";


contract gokitownwtf is ERC721A, Ownable {
  using Strings for uint256;
  
  bool public isActive = false;
  string public URI = "https://gateway.pinata.cloud/ipfs/QmUvMHT1HXEwR3fqty4XRvGYYNLwtCSeJdj6rBUuvU3u4S/";
  uint256 public mintPrice = 0.004 ether;
  uint256 public constant MAX_SUPPLY = 10000;
  uint256 public maxAllowedTokensPerPurchase = 10;
  uint256 public CLAIMED_SUPPLY;

  constructor() ERC721A("gokitownwtf", "GTWN") { }

  modifier saleIsOpen {
    require(totalSupply() <= MAX_SUPPLY, "Sale has ended.");
    _;
  }

  modifier onlyAuthorized() {
    require(owner() == msg.sender);
    _;
  }

  function toggleSale() public onlyAuthorized {
    isActive = !isActive;
  }

  function setPrice(uint256 _price) public onlyAuthorized {
    mintPrice = _price;
  }

  function setBaseURI(string memory baseURI) public onlyAuthorized {
    URI = baseURI;
  }
 
  function Mint(uint256 _count) public payable saleIsOpen {
    uint256 mintIndex = totalSupply();
    uint256 discountPrice = _count;

    if (msg.sender != owner()) {
      require(isActive, "Sale is not active currently.");
    }

    require(mintIndex + _count <= MAX_SUPPLY, "Total supply exceeded.");
    require(
      _count <= maxAllowedTokensPerPurchase,
      "Exceeds maximum allowed tokens"
    );

    if(_count > 1){
      discountPrice = _count - 1;
    }

    if(balanceOf(msg.sender) >= 1 || _count > 1) {
      require(msg.value >= mintPrice * discountPrice, "Insufficient ETH amount sent.");
    }
   
    _safeMint(msg.sender, _count);
    CLAIMED_SUPPLY += _count;


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
    string memory currentBaseURI = URI;
    return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
        : "";
  }

  function withdraw() external onlyAuthorized {
    uint balance = address(this).balance;
    payable(owner()).transfer(balance);
  }
} 