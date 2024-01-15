// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract Mentaverse1 is ERC721A, Ownable {

  // Max Supply
  uint32 public constant MAX_SUPPLY = 300;
  uint32 public constant MAX_PRESALE_SUPPLY = 300;

  // Price
  uint256 public constant PUBLIC_SALE_PRICE = 0.22 ether;
  uint256 public constant PRE_SALE_PRICE = 0.2 ether;

  // Time
  uint256 public timestampPreSale = 0; // 1661576400 2022-08-27 13:00:00
  uint256 public timestampPublicSale = 0; // 1661662800 2022-08-28 13:00:00

  string private baseTokenUri;
  string public placeholderTokenUri;

  bool public isRevealed = false;

  mapping(address => uint32) public whitelist;

  constructor() ERC721A("Mentaverse", "MENTA") {}

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function setTime(
    uint256 _timestampPreSale, 
    uint256 _timestampPublicSale) external onlyOwner{
      require(_timestampPreSale > 0, "Time set already");
      require(block.timestamp < _timestampPreSale, "Pre Sale must be the day afterward");
      require(_timestampPreSale < _timestampPublicSale, "Pre Sale must earlier than Public Sale");
      timestampPreSale = _timestampPreSale;
      timestampPublicSale = _timestampPublicSale;
  }

  function setTokenUri(string memory _baseTokenUri) external onlyOwner {
    baseTokenUri = _baseTokenUri;
  }

  function setPlaceholderTokenUri(string memory _placeholderTokenUri) external onlyOwner {
    placeholderTokenUri= _placeholderTokenUri;
  }

  function seedWhiteList(address[] memory addresses) external onlyOwner {
    for (uint256 i = 0 ; i < addresses.length ; i++) {
      whitelist[addresses[i]] = 2;
    }
  }

  function toggleReveal() external onlyOwner {
    isRevealed = !isRevealed;
  }

  function withdraw() external onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function isPublicSales() public view returns (bool) {
    return timestampPublicSale > 0 
      && block.timestamp >= timestampPublicSale;
  }

  function isPreSale() public view returns (bool){
    return timestampPreSale > 0
      && block.timestamp >= timestampPreSale
      && block.timestamp <= timestampPublicSale;
  }

  function publicMint(uint32 quantity) external payable callerIsUser{
    require(isPublicSales(), "Public sales not yet started");
    require((totalSupply() + quantity) <= MAX_SUPPLY, "Reach max supply");
    require((PUBLIC_SALE_PRICE * quantity) <= msg.value, "Not enough token");
    _mint(msg.sender, quantity);
  }

  function whitelistMint(uint32 quantity) external payable callerIsUser{
    require(isPreSale(), "Pre sales not yet started");
    require(whitelist[msg.sender] >= quantity, "Not enough whitelist quota");
    require((totalSupply() + quantity) <= MAX_PRESALE_SUPPLY, "Reach max supply");
    require((PRE_SALE_PRICE * quantity) <= msg.value, "Not enough token");
    whitelist[msg.sender] -= quantity;
    _mint(msg.sender, quantity);
  }

  function airDrop(address to, uint256 quantity) external onlyOwner {
    require((totalSupply() + quantity) <= MAX_SUPPLY, "Reach max supply");
    _mint(to, quantity);
  }

  function adminMint(uint256 quantity) external onlyOwner {
    require((totalSupply() + quantity) <= MAX_SUPPLY, "Reach max supply");
    _mint(msg.sender, quantity);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenUri;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    if(!isRevealed){
        return placeholderTokenUri;
    }
    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : "";
  }

}
