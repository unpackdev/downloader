// SPDX-License-Identifier: MIT
// @Proteu5: Special Thanks To The Azuki Team & Chiru Labs For Releasing Their Contract Code
/*
/* ███╗   ██╗███████╗██╗  ██╗██╗   ██╗███████╗
/* ████╗  ██║██╔════╝╚██╗██╔╝██║   ██║██╔════╝
/* ██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║███████╗
/* ██║╚██╗██║██╔══╝   ██╔██╗ ██║   ██║╚════██║
/* ██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝███████║
/* ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝                               
/* 
/* A Collection By: Encode.Graphics & @Pr1mal_Cypher
*/
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract Nexu5 is ERC721A, Ownable, ReentrancyGuard {
  uint256 public immutable maxPerAddressDuringMint;
  uint256 public immutable amountForDevs;
  uint256 public immutable amountForFounders;
  uint256 public count;
  bool paused = false;

  struct SaleConfig {
    uint64 publicPrice;
  }

  SaleConfig public saleConfig;

  mapping(address => uint256) public allowlist;

  mapping(address => uint256) public founderlist;

  constructor(
    uint256 maxBatchSize_, 
    uint256 collectionSize_, 
    uint256 amountForFounders_, 
    uint256 amountForDevs_
  ) ERC721A("Nexu5v2", "NEX5", maxBatchSize_, collectionSize_) {
    maxPerAddressDuringMint = maxBatchSize_;
    amountForFounders = amountForFounders_;
    amountForDevs = amountForDevs_;

    require(
      amountForFounders_ <= collectionSize_,
      "larger collection"
    );
  }
  
  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller = contract");
    _;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
        return 0;
    }
  
  function returnFounderQty() public view returns (uint256){
    return founderlist[msg.sender];
  }

  function pause(bool _state) external onlyOwner returns (bool){
    paused = _state;
    return paused;

  }

  function founderMint(uint256 quantity) external payable callerIsUser {
    require(paused == false, "Contract is paused");
    require(founderlist[msg.sender] > 0, "not eligible");
    require(
      totalSupply() + quantity <= amountForFounders,
      "not enough remaining reserved"
    );
    require(
      numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint,
      "too many"
    );
    //uint256 totalCost = getFounderPrice();
    founderlist[msg.sender] -= quantity;
    _safeMint(msg.sender, quantity);
  }

  function allowlistMint(uint256 quantity) external payable callerIsUser {
    require(paused == false, "paused");
    require(allowlist[msg.sender] > 0, "not eligible");
    require(totalSupply() + quantity <= amountForDevs, "max supply");
    allowlist[msg.sender]-= quantity;
    _safeMint(msg.sender, quantity);
  }

  function publicSaleMint(uint256 quantity)
    external
    payable
    callerIsUser
  {
    SaleConfig memory config = saleConfig;
    uint256 publicPrice = uint256(config.publicPrice);
    require(paused == false, "paused");
    if (msg.sender == address(0)) revert ("zero address");
    //require(msg.sender != address(0), "ERC721A: != mint 0 address");
    require(
      isPublicSaleOn(publicPrice),
      "public sale != true"
    );
    require(totalSupply() + quantity <= collectionSize, "@ max supply");
    require(
      numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint,
      "can not mint this many"
    );
    require(msg.value >= publicPrice * quantity, "add funds");
    count += quantity;
    _safeMint(msg.sender, quantity);
  }

 function isPublicSaleOn(
    uint256 publicPriceWei
  ) public pure returns (bool) {
    if(publicPriceWei != 0)
    {
        return true;
    }
  }

 uint256 public constant FOUNDER_TOKEN_PRICE = 0 ether;

 function getFounderPrice()
    public
    pure
    returns (uint256)
  {
    return FOUNDER_TOKEN_PRICE;
  }

  function SetupPublicSaleInfo(
    uint64 _publicPriceWei
  ) external onlyOwner {
      saleConfig.publicPrice = _publicPriceWei;
  }

  function seedAllowlist(address[] memory addresses, uint256[] memory numSlots)
    external
    onlyOwner
  {
    require(
      addresses.length == numSlots.length,
      "addresses does not match numSlots length"
    );
    for (uint256 i = 0; i < addresses.length; i++) {
      allowlist[addresses[i]] = numSlots[i];
    }
  }

 function isWhitelisted(address _user) public view returns (bool) {
        if(allowlist[_user] > 0)
        {
            return true;
        }
        return false;
  }

  function remFounderUser(address _user) public onlyOwner
  {
    delete founderlist[_user];
  }

  function remWhitelistUser(address _user) public onlyOwner
  {
    delete allowlist[_user];
  }

  function seedFounderlist(address[] memory addresses, uint256[] memory numSlots)
    external
    onlyOwner
  {
    require(
      addresses.length == numSlots.length,
      "addresses != numSlots.len"
    );
    for (uint256 i = 0; i < addresses.length; i++) {
      founderlist[addresses[i]] = numSlots[i];
    }
  }

  function isFounderlisted(address _user) public view returns (bool) {
        if(founderlist[_user] > 0)
        {
            return true;
        }
        return false;
  }

  function devMint(uint256 quantity) external onlyOwner {
    require(paused == false, 'Contract is paused');
    require(
      totalSupply() + quantity <= amountForDevs,
      "Dev Mint First"
    );
    require(
      quantity % maxBatchSize == 0,
      "* of maxBatchSize only"
    );
    uint256 numChunks = quantity / maxBatchSize;
    for (uint256 i = 0; i < numChunks; i++) {
      _safeMint(msg.sender, maxBatchSize);
    }
  }

 function totalMinted() public view returns (uint256) {
    return _totalMinted();
 }


 function exists(uint256 tokenId) public view returns (bool) {
    return _exists(tokenId);
 }

  string private _baseTokenURI;

  function _tokenURI(uint256 tokenId) public view returns (string memory) {
    return tokenURI(tokenId);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function withdraw() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Txn failed.");
  }

  function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
    _setOwnersExplicit(quantity);
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }
}