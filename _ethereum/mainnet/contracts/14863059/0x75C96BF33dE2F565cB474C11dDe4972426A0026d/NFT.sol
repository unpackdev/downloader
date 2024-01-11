// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol"; 

contract NotInvited is ERC721A, Ownable, ReentrancyGuard {
  using Address for address;
  using Strings for uint;

  string  public  baseTokenURI = "ipfs://Qmaf2ajPyXEPnKun9D7HgcbLvuPbk2kbRgc3htkgFq6rW4";


  uint256 public  maxSupply = 1000;
  //uint256 public  freeMints = 1000;
  uint256 public  PUBLIC_SALE_PRICE = 0 ether;
  bool public isPublicSaleActive = true;


  constructor() ERC721A("NotInvited", "NI") {}
/*
  function mint(uint256 numberOfTokens)
      external
      payable
  {
    require(numberOfTokens > 0, "Invalid mint amount");
    require(isPublicSaleActive, "Public sale is not open");
    require(totalSupply() + numberOfTokens <= maxSupply,"Max supply excceeded");

//    V1. Without Free Mints
    require((PUBLIC_SALE_PRICE * numberOfTokens) <= msg.value, "Incorrect ETH value sent" );
    _safeMint(msg.sender, numberOfTokens);


//    V2. With Free Mints
//    require((PUBLIC_SALE_PRICE * numberOfTokens) <= msg.value || totalSupply() + numberOfTokens < freeMints, "Incorrect ETH value sent" );
  
  _safeMint(msg.sender, numberOfTokens);
  }
*/
function mint() external {
   require(isPublicSaleActive, "Public sale is not open");
    require(totalSupply() < maxSupply,"Max supply excceeded");
    require(balanceOf(msg.sender) == 0,"User can only mint 1 NFT");
    _safeMint(msg.sender, 1);
}

 function treasuryMint(uint quantity, address user)
    public
    onlyOwner
  {
    require(
      quantity > 0,
      "Invalid mint amount"
    );
    require(
      totalSupply() + quantity <= maxSupply,
      "Maximum supply exceeded"
    );
    _safeMint(user, quantity);
  }


  function setBaseURI(string memory baseURI)
    public
    onlyOwner
  {
    baseTokenURI = baseURI;
  }


  function withdraw()
    public
    onlyOwner
    nonReentrant
  {
    Address.sendValue(payable(msg.sender), address(this).balance);
  }

  function tokenURI(uint _tokenId)
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
    return string(abi.encodePacked(baseTokenURI, "/", _tokenId.toString(), ".json"));
  }

  function _baseURI()
    internal
    view
    virtual
    override
    returns (string memory)
  {
    return baseTokenURI;
  }

  function setIsPublicSaleActive(bool _isPublicSaleActive)
      external
      onlyOwner
  {
      isPublicSaleActive = _isPublicSaleActive;
  }


  function setSalePrice(uint256 _price)
      external
      onlyOwner
  {
      PUBLIC_SALE_PRICE = _price;
  }



}
