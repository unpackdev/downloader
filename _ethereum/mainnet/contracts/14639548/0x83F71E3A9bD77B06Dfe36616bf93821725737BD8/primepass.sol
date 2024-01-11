// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./ERC721A.sol";

contract PrimePass is Ownable, ERC721A, ReentrancyGuard {

  struct SaleConfig {
    uint32 publicsaleStartTime;
    uint32 publicsalePeriod;
    uint64 publicsalePrice;
    bool isFinished;
  }
  
  SaleConfig public saleConfig;

  constructor( uint256 maxBatchSize_, uint256 collectionSize_ ) 
    ERC721A("Prime Pass", "Prime Pass", maxBatchSize_, collectionSize_) {
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  modifier afterClosed() {
    require(saleConfig.isFinished == true);
    require(uint256(block.timestamp) >= uint256(saleConfig.publicsaleStartTime) + uint256(saleConfig.publicsalePeriod), "sale has not finished yet");
    _;
  }

  function setSaleInfo(uint32 timestamp, uint32 _publicsalePeriod, uint64 _publicsalePrice) external onlyOwner {
    saleConfig.publicsaleStartTime = timestamp;
    saleConfig.publicsalePeriod = _publicsalePeriod;
    saleConfig.publicsalePrice = _publicsalePrice;
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

  function setFinished() external onlyOwner(){
    saleConfig.isFinished = true;
  }

  function mint(uint256 quantity) external payable{
    require(saleConfig.isFinished == false , "Sale is finished.");

    uint256 _publicsaleStartTime = uint256(saleConfig.publicsaleStartTime);
    uint256 _publicsalePeriod = uint256(saleConfig.publicsalePeriod);
    uint256 _publicsalePrice = uint256(saleConfig.publicsalePrice);
    
    require(_publicsaleStartTime != 0, "saleConfig is needed.");
    require(uint256(block.timestamp) >= _publicsaleStartTime, "sale has not started yet");
    require(uint256(block.timestamp) < _publicsaleStartTime + _publicsalePeriod, "sale has finished");
    require(totalSupply() + quantity <= collectionSize, "reached max supply");

    refundIfOver(_publicsalePrice * quantity);
    _safeMint(msg.sender, quantity);
  }

  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "Need to send more ETH.");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

  function withdrawMoney() external onlyOwner nonReentrant afterClosed{
    uint256 balance = address(this).balance;
    require(balance > 0, "Balance is zero");

    // this function will throws exception when performed unsuccessfully.
    payable(msg.sender).transfer(address(this).balance);
  }
}