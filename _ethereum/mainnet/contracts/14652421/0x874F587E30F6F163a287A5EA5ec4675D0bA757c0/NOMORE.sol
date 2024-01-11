// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./ERC721A.sol";

contract NOMORE is ERC721A, Ownable, ReentrancyGuard {
  using ECDSA for bytes32;

  uint256 public constant MAX_SUPPLY = 5000;

  uint256 public constant MAX_PER_OG = 4;
  uint256 public constant OG_PRICE = 0.09 ether;

  uint256 public constant MAX_PER_WHITELIST = 2;
  uint256 public constant WHITELIST_PRICE = 0.09 ether;

  uint256 public constant MAX_PER_PUBLIC = 2;
  uint256 public constant PUBLIC_PRICE = 0.18 ether;

  mapping(address => uint8) public publicMinted;

  string public baseURI;

  event Minted(address minter, uint256 quantity);
  event Reserved(address recipient, uint256 quantity);
  event BaseURIChanged(string newBaseURI);

  constructor(string memory initbaseURI) ERC721A("NOMORECLUB", "NOMORE") {
    baseURI = initbaseURI;
  }

  function ogMint(
    uint256 quantity, 
    string calldata salt, 
    bytes calldata signature
  ) external payable {
    require(tx.origin == msg.sender, "NOMORE: contract is not allowed");
    require(quantity > 0 && quantity <= MAX_PER_OG, "NOMORE: invalid quantity");
    require(totalSupply() + quantity <= MAX_SUPPLY, "NOMORE: reached max supply");
    require(numberMinted(msg.sender) + quantity <= MAX_PER_OG, "NOMORE: max mint exceeded");
    require(_verify(_hash(msg.sender, 1, salt), signature), "NOMORE: invalid signature");
    _safeMint(msg.sender, quantity);
    checkAndRefundIfOver(OG_PRICE * quantity);
    emit Minted(msg.sender, quantity);
  }

  function whitelistMint(
    uint256 quantity, 
    string calldata salt, 
    bytes calldata signature
  ) external payable {
    require(tx.origin == msg.sender, "NOMORE: contract is not allowed");
    require(quantity > 0 && quantity <= MAX_PER_WHITELIST, "NOMORE: invalid quantity");
    require(totalSupply() + quantity <= MAX_SUPPLY, "NOMORE: reached max supply");
    require(numberMinted(msg.sender) + quantity <= MAX_PER_WHITELIST, "NOMORE: max mint exceeded");
    require(_verify(_hash(msg.sender, 2, salt), signature), "NOMORE: invalid signature");
    _safeMint(msg.sender, quantity);
    checkAndRefundIfOver(WHITELIST_PRICE * quantity);
    emit Minted(msg.sender, quantity);
  }

  function raffleMint(
    uint256 quantity, 
    string calldata salt, 
    bytes calldata signature
  ) external payable {
    require(tx.origin == msg.sender, "NOMORE: contract is not allowed");
    require(quantity > 0 && quantity <= MAX_PER_PUBLIC, "NOMORE: invalid quantity");
    require(totalSupply() + quantity <= MAX_SUPPLY, "NOMORE: reached max supply");
    require(publicMinted[msg.sender] + quantity <= MAX_PER_PUBLIC, "NOMORE: max mint exceeded");
    require(_verify(_hash(msg.sender, 3, salt), signature), "NOMORE: invalid signature");
    publicMinted[msg.sender] += uint8(quantity);
    _safeMint(msg.sender, quantity);
    checkAndRefundIfOver(PUBLIC_PRICE * quantity);
    emit Minted(msg.sender, quantity);
  }

  function auctionMint(
    uint256 quantity, 
    uint256 price,
    string calldata salt, 
    bytes calldata signature
  ) external payable {
    require(tx.origin == msg.sender, "NOMORE: contract is not allowed");
    require(quantity > 0 && quantity <= MAX_PER_PUBLIC, "NOMORE: invalid quantity");
    require(totalSupply() + quantity <= MAX_SUPPLY, "NOMORE: reached max supply");
    require(publicMinted[msg.sender] + quantity <= MAX_PER_PUBLIC, "NOMORE: max mint exceeded");
    require(_verify(keccak256(abi.encode(address(this), msg.sender, 4, price, salt)), signature), "NOMORE: invalid signature");
    require(price > WHITELIST_PRICE && price <= PUBLIC_PRICE, "NOMORE: invalid price");
    publicMinted[msg.sender] += uint8(quantity);
    _safeMint(msg.sender, quantity);
    checkAndRefundIfOver(price * quantity);
    emit Minted(msg.sender, quantity);
  }

  function _hash(
    address recipient,
    uint8 mode,
    string calldata salt
  ) internal view returns (bytes32) {
    return keccak256(abi.encode(address(this), recipient, mode, salt));
  }

  function _verify(
    bytes32 hash, bytes memory signature
  ) internal view returns (bool) {
    return (_recover(hash, signature) == owner());
  }

  function _recover(
    bytes32 hash, bytes memory signature
  ) internal pure returns (address) {
      return hash.toEthSignedMessageHash().recover(signature);
  }

  function checkAndRefundIfOver(uint256 price) private {
    require(msg.value >= price, "NOMORE: need to send more ETH");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

  function reserve(
    address recipient, uint256 quantity
  ) external onlyOwner {
    require(totalSupply() + quantity <= MAX_SUPPLY, "NOMORE: reached max supply");
    _safeMint(recipient, quantity);
    emit Reserved(recipient, quantity);
  }

  function reserveBatch(
    address[] calldata recipients, uint256 quantity
  ) external onlyOwner {
    uint256 total = recipients.length * quantity;
    require(totalSupply() + total <= MAX_SUPPLY, "NOMORE: reached max supply");
    for (uint256 i = 0; i < recipients.length; ++i) {
      _safeMint(recipients[i], quantity);
      emit Reserved(recipients[i], quantity);
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string calldata newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
    emit BaseURIChanged(newBaseURI);
  }

  function withdraw() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function numberMinted(address _owner) public view returns (uint256) {
    return _numberMinted(_owner);
  }

  function getOwnershipData(
    uint256 tokenId
  ) external view returns (TokenOwnership memory) {
    return ownershipOf(tokenId);
  }

  function tokensOfOwner(address _owner) external view returns (uint[] memory) {
    uint tokenCount = balanceOf(_owner);
    uint[] memory tokensId = new uint256[](tokenCount);
    for (uint i = 0; i < tokenCount; i++) {
        tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokensId;
  }
}