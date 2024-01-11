// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./ERC721A.sol";

contract BaihuGenesis is Ownable, ERC721A, ReentrancyGuard {

  struct SaleConfig {
    uint32 presaleStartTime;
    uint32 publicsaleStartTime;
    uint32 publicsalePeriod;
    uint64 presalePrice;
    uint64 publicsalePrice;
    uint64 publicsaleMaxMint;
    bool isFinished;
  }
  
  SaleConfig private saleConfig;
  
  mapping(address => bool) private allowList; // WhiteList
  mapping(address => uint256) private numberMintedInPublicSale;
  
  uint256 private reserved = 40; // Total amount of tokens for teamMint

  constructor( uint256 maxBatchSize_, uint256 collectionSize_ ) ERC721A("Baihu Genesis", "Baihu Genesis", maxBatchSize_, collectionSize_){}

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  modifier onlyWhiteList() {
    require(block.timestamp >= saleConfig.publicsaleStartTime || (block.timestamp < saleConfig.publicsaleStartTime && allowList[msg.sender] == true), "The caller is not in WhiteList");
    //require(allowList[msg.sender] == true, "The caller is not in WhiteList");
    _;
  }

  function setSaleInfo(uint32 timestamp, uint32 presalePeriod, uint32 publicsalePeriod, uint64 _presalePrice, uint64 _publicsalePrice, uint64 _publicsaleMaxMint) external onlyOwner {
    saleConfig.presaleStartTime = timestamp;
    saleConfig.publicsaleStartTime = timestamp + presalePeriod;
    saleConfig.publicsalePeriod = publicsalePeriod;
    saleConfig.presalePrice = _presalePrice;
    saleConfig.publicsalePrice = _publicsalePrice;
    saleConfig.publicsaleMaxMint = _publicsaleMaxMint;
    saleConfig.isFinished = false;
  }

  // metadata URI
  string private _baseTokenURI;
  string private _traitsURI;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  /**
   * @dev set the _baseTokenURI
   * @param baseURI of the _baseTokenURI
   */
  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function setTraitsURI(string calldata traitsURI) external onlyOwner {
    _traitsURI = traitsURI;
  }

  function baseTokenURI() public view returns (string memory) {
    return _baseTokenURI;
  }

  function mint(uint256 quantity) external payable onlyWhiteList {
    require(saleConfig.isFinished == false , "Sale is finished.");

    uint256 _saleStartTime = uint256(saleConfig.presaleStartTime);
    uint256 _publicsaleStartTime = uint256(saleConfig.publicsaleStartTime);
    uint256 _presalePrice = uint256(saleConfig.presalePrice);
    uint256 _publicsalePrice = uint256(saleConfig.publicsalePrice);
    uint256 _publicsaleMaxMint = uint256(saleConfig.publicsaleMaxMint);
    
    require(_saleStartTime != 0, "saleConfig is needed.");
    require(uint256(block.timestamp) >= _saleStartTime, "presale has not started yet");
    require(totalSupply() + quantity <= collectionSize, "reached max supply");

    if (uint256(block.timestamp) <= _publicsaleStartTime) {
      refundIfOver(_presalePrice * quantity);
    }
    else {
      require(
        numberMintedInPublicSale[msg.sender] + quantity <= _publicsaleMaxMint,
        "can not mint this many in public sale"
      );
      refundIfOver(_publicsalePrice * quantity);
      numberMintedInPublicSale[msg.sender] += quantity;
    }
    _safeMint(msg.sender, quantity);
  }

  function seedWhitelist(address[] memory addresses) external onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      allowList[addresses[i]] = true;
    }
  }

  function removeFromWhitelist(address[] memory addresses) external onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      allowList[addresses[i]] = false;
    }
  }

  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "Need to send more ETH.");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

  function teamMint() external onlyOwner {
    require(reserved > 0, "You already did teamMint before.");
    require(totalSupply() + reserved <= collectionSize, "reached max supply");

    _safeMint(msg.sender, reserved);
    reserved = 0;
  }

  function withdrawMoney() external onlyOwner nonReentrant {
    uint256 balance = address(this).balance;
    require(balance > 0, "Balance is zero");

    // this function will throws exception when performed unsuccessfully.
    payable(msg.sender).transfer(address(this).balance);
  }
}