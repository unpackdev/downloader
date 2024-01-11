// SPDX-License-Identifier: MIT
// Dan Thurber DDT0
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";
contract MetaArtz is Ownable, ERC721A, ReentrancyGuard {
  uint256 public maxPerAddressDuringMint = 1000;
  uint256 public maxMintPerAddressTW = 8000;
  uint256 public Tmint = 0.0001 ether;
  uint256 public mintlistPrice = 0.1 ether;
  uint256 public maxBatchSize_ = 9999;
  uint256 public collectionSize_ = 10000;
  bool public onlyWhitelisted = true;
  bool public paused = false;
  mapping(address => uint256) public allowlist;
  constructor()
    ERC721A("MetaArtz Genesis Pass", "Artz", maxBatchSize_, collectionSize_) 
  {
  }
  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }
  function WhiteListMint(uint256 quantity) external payable callerIsUser {
    uint256 price = uint256(mintlistPrice);
    require(price != 0, "WhiteList sale has not begun yet");
    require(!paused, "Not Alowed Is Paused");
    require(allowlist[msg.sender] > 0, "not eligible for WhiteList mint");
    require(totalSupply() + 1 <= collectionSize, "reached max supply");
    allowlist[msg.sender] -= quantity;
    require( numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint, "You can not mint this many");
    _safeMint(msg.sender, quantity);
    refundIfOver(price * quantity );
  }
  function TWMint(uint256 quantity) external payable callerIsUser {
    uint256 priceTW = uint256(Tmint);
    require(!paused, "Not Alowed Is Paused"); 
    require(allowlist[msg.sender] > 0, "not eligible for WhiteList mint");
    allowlist[msg.sender] -= quantity;
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(numberMinted(msg.sender) + quantity <= maxMintPerAddressTW,"can not mint this many");
    _safeMint(msg.sender, quantity);
    refundIfOver(priceTW * quantity);
  }
  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "Need to send more ETH.");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }
  function isPublicSaleOn(
  ) public view returns (bool) {
  }
  function WhiteListArray(address[] memory addresses, uint256[] memory numSlots)
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
  function StartTWMint(bool _state) public onlyOwner {
    paused = _state;
  }
  // // metadata URI
  string private _baseTokenURI;
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }
  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }
  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
    _setOwnersExplicit(quantity);
  }
  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }
  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }
}