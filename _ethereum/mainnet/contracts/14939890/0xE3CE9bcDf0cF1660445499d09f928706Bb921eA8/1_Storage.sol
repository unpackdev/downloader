// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
 
contract DegenDickBros is Ownable, ERC721A, ReentrancyGuard {
  bool public isPaused = true;
  uint256 public immutable collectionSize;
  uint256 public immutable maxBatchSize;
  uint256 public immutable amountForDevs;
  uint256 public price;
  uint256 public immutable allowlistPrice;
  bool private _isMetadataLocked;

  mapping(address => uint16) public allowlist;

  constructor(
    uint256 maxBatchSize_,
    uint256 collectionSize_,
    uint256 amountForDevs_,
    uint256 price_,
    uint256 allowlistPrice_,
    string memory baseURI_,
    uint256 numberOfHonoraries_
  ) ERC721A("DegenDickBros", "DDB") {  
    maxBatchSize = maxBatchSize_;
    collectionSize = collectionSize_;
    amountForDevs = amountForDevs_;
    price = price_;
    allowlistPrice = allowlistPrice_;
    _baseTokenURI = baseURI_;
    _safeMint(msg.sender, numberOfHonoraries_);
  }

  function mint(uint256 quantity) external payable callerIsUser {  
    require(
      !isPaused, 
      "contract is paused"
    );
    _doMint(quantity, price);
  }

  function refundIfOver(uint256 price_) private { 
    require(msg.value >= price_, "need to send more ETH.");
    if (msg.value > price_) {
      payable(msg.sender).transfer(msg.value - price_);
    }
  }

  function changePrice(uint256 price_) external onlyOwner {
    price = price_;
  }

  function pause() external onlyOwner { 
    require(
      !isPaused, 
      "contract already paused");
    isPaused = true;
  }

  function unpause() external onlyOwner { 
    require(
      isPaused, 
      "contract already unpaused");
    isPaused = false;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner { 
    require (!_isMetadataLocked, "metadata is locked");
    _baseTokenURI = baseURI;
  }

  function lockMetadata() external onlyOwner {
    require(!_isMetadataLocked, "metadata already locked");
    _isMetadataLocked = true;
  }

  function withdraw() external onlyOwner nonReentrant { 
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "transfer failed.");
  }

   // For marketing etc.
  function devMint(uint256 quantity) external onlyOwner { 
    require(
      totalSupply() + quantity <= amountForDevs,
      "too many already minted before dev mint"
    );
    require(
      quantity % maxBatchSize == 0,
      "can only mint a multiple of the maxBatchSize"
    );
    uint256 numChunks = quantity / maxBatchSize;
    for (uint256 i = 0; i < numChunks; i++) {
      _safeMint(msg.sender, maxBatchSize);
    }
  }

  function allowlistMint(uint256 quantity) external payable callerIsUser { 
    require(allowlist[msg.sender] > 0, "not eligible for allowlist mint");
    require(totalSupply() + 1 <= collectionSize, "reached max supply");

    _doMint(quantity, allowlistPrice);
    allowlist[msg.sender] = uint16(allowlist[msg.sender] - quantity);
  }

  function seedAllowlist(address[] memory addresses) external onlyOwner { 
    for (uint256 i = 0; i < addresses.length; i++) {
      allowlist[addresses[i]] = 10;
    }
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "the caller is another contract");
    _;
  }

  function _doMint(uint256 quantity, uint256 price_) private {
    require(
      totalSupply() + quantity <= collectionSize, 
      "reached max supply"
    );

    require(
      numberMinted(msg.sender) + quantity <= maxBatchSize,
      "can not mint this many"
    );

    _safeMint(msg.sender, quantity);
    refundIfOver(price_ * quantity);
  }

  // metadata URI
  string private _baseTokenURI;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }
}