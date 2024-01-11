// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./console.sol";
import "./ERC721A.sol"; 
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract TheHouseOfInsomnia is ERC721A, Ownable, ReentrancyGuard{
  uint256 public constant collectionSize = 1000;
  uint256 public constant reservedTokens = 100;
  
  struct SaleConfig {
    uint32 startTime;
    uint32 endTime;
    uint64 price;
  }

  SaleConfig public saleConfig;

  mapping(address => uint256) public allowlist;
  mapping(address => uint256) public numberClaimed;
  uint256 public reservedTokensMinted = 0;

  bool public revealed = false;

  constructor() ERC721A("The House Of Insomnia", "THOI") {
  }

  function mintToken(uint256 quantity) external payable {
    require(isSaleOn(), "sale has not begun yet");
    require(numberClaimed[msg.sender] + quantity <= allowlist[msg.sender], "excceds mint limit");
    require(totalSupply() + quantity <= collectionSize - (reservedTokens - reservedTokensMinted), "reached max supply");

    uint256 totalPrice = saleConfig.price * quantity;    
    require(msg.value >= totalPrice, "Need to send more ETH.");
    
    numberClaimed[msg.sender] += quantity;
    _safeMint(msg.sender, quantity);
  }
  
  function teamMint(uint256 quantity) external payable onlyOwner {
    require(reservedTokensMinted + quantity <= reservedTokens, "excceds mint limit");
    reservedTokensMinted += quantity;
    _safeMint(msg.sender, quantity);
  }

  function isSaleOn() public view returns (bool) {
    uint32 startTime = saleConfig.startTime;
    if (startTime == 0) {
      return false;
    }
    
    uint32 endTime = saleConfig.endTime;    
    if (endTime == 0){
      return block.timestamp >= startTime;
    }
    
    return block.timestamp >= startTime && block.timestamp < endTime;
  }
  
  function setSaleConfig(uint32 startTime, uint32 endTime, uint64 priceWei) external onlyOwner {
    saleConfig = SaleConfig(
      startTime,
      endTime,
      priceWei
    );
  }

  function seedAllowlist(address[] memory addresses, uint256[] memory numSlots) external onlyOwner {
    require(addresses.length == numSlots.length, "addresses does not match numSlots length");
    for (uint256 i = 0; i < addresses.length; i++) {
      allowlist[addresses[i]] = numSlots[i];
    }
  }
    
  function reveal() public onlyOwner {
    revealed = true;
  }

  // metadata URI
  string private _baseTokenURI;
  string private _placeholderTokenUri;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function setPlaceholderUri(string memory placeholderTokenUri) external onlyOwner{
    _placeholderTokenUri = placeholderTokenUri;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
    
    if(revealed == false) {
        return _placeholderTokenUri;
    }
    
    string memory _tokenURI = super.tokenURI(tokenId);
    return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI, ".json")) : "";
  }

  function withdraw() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }
  
  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
    return _ownershipOf(tokenId);
  }
}
