// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "./ECDSA.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./DefaultOperatorFilterer721.sol";

contract DollIsland is Ownable, ERC721A, DefaultOperatorFilterer721 {
  using ECDSA for bytes32;
  using Strings for uint256;

  struct SaleConfig {
    uint256 presalePrice;
    uint256 publicPrice;
  }

  SaleConfig public saleConfig;

  bool public saleIsActive;
  bool public presaleIsActive;

  uint256 private maxBatchSize;
  uint256 public collectionSize;
  uint256 public presaleSize;
  uint256 public reserved;

  string private baseTokenURI;
  bool public revealed;

  mapping(address => uint256) public userToUsedNonce;
  mapping(address => bool) public userToMinted;
  mapping(address => bool) internal _publicFreeMinted;
  address public signer;

  constructor() ERC721A("DollIsland", "DOLL") DefaultOperatorFilterer721() {
    collectionSize = 5000;
    presaleSize = 3000;
    maxBatchSize = 5;
    saleConfig.presalePrice = 0.005 ether;
    saleConfig.publicPrice = 0.0066 ether;

    // withdrawalProxy = WithdrawalProxy(proxyAddress);
  }

  modifier noContract() {
    require(tx.origin == msg.sender, "No contract call");
    _;
  }

  function presaleMint(
    uint256 quantity,
    bool isWhiltelist,
    bool isHolder,
    bytes calldata signature
  ) external payable {
    require(presaleIsActive, "presale is not active");
    require(verifyFreemintSignature(isWhiltelist, isHolder, signature), "can only mint with whitelist signature");
    require(totalSupply() + quantity <= presaleSize, "max supply reached in presale phase");
    require(msg.value >= saleConfig.presalePrice * quantity, "insufficient funds");
    require(quantity <= maxBatchSize, "can at most mint 5 at once ");

    super._safeMint(msg.sender, quantity);
  }

  function freeMint(
    bool isWhitelist,
    bool isHolder,
    bytes calldata signature
  ) external payable noContract {
    require(presaleIsActive, "presale is not active");
    require(verifyFreemintSignature(isWhitelist, isHolder, signature), "can only mint with whitelist and holder signature");
    require(userToMinted[msg.sender] == false, "can only mint once");
    require(totalSupply() <= presaleSize, "there are no free mints left");

    // whitelist mint
    if (isWhitelist && isHolder) {
      super._safeMint(msg.sender, 5);
      userToMinted[msg.sender] = true;
      // holder mint
    } else if (isHolder) {
      super._safeMint(msg.sender, 5);
      userToMinted[msg.sender] = true;
    } else if (isWhitelist) {
      // whitelist and holder mint
      super._safeMint(msg.sender, 2);
      userToMinted[msg.sender] = true;
    }
  }

  function publicMint(uint256 quantity) external payable noContract {
    require(saleIsActive, "sale is not active");
    require(quantity <= maxBatchSize, "can at most mint 5 token per transaction");
    require(totalSupply() + quantity <= collectionSize, "max supply reached");
    require(msg.value >= findMintCost(quantity), "insufficient funds");
    _publicFreeMinted[msg.sender] = true;
    super._safeMint(msg.sender, quantity);
  }

  function findMintCost(uint256 quantity) public view returns (uint256) {
    return saleConfig.publicPrice * quantity - (_publicFreeMinted[msg.sender] ? 0 : saleConfig.publicPrice);
  }

  function verifyFreemintSignature(
    bool isWhitelist,
    bool isHolder,
    bytes calldata signature
  ) internal view returns (bool) {
    require(isWhitelist || isHolder, "must be whitelist or holder");
    address recoveredAddress = keccak256(abi.encodePacked(msg.sender, isWhitelist, isHolder)).toEthSignedMessageHash().recover(signature);
    return (recoveredAddress != address(0) && recoveredAddress == signer);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override(ERC721A) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  /**
   * @dev implements operator-filter-registry blocklist filtering because https://opensea.io/blog/announcements/on-creator-fees/
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override(ERC721A) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  /**
   * @dev implements operator-filter-registry blocklist filtering because https://opensea.io/blog/announcements/on-creator-fees/
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public override(ERC721A) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  function setPrice(uint256 _presalePrice, uint256 _publicPrice) external onlyOwner {
    saleConfig.presalePrice = _presalePrice;
    saleConfig.publicPrice = _publicPrice;
  }

  function setMaxBatchSize(uint256 _maxBatchSize) external onlyOwner {
    maxBatchSize = _maxBatchSize;
  }

  function setBaseURI(string calldata _baseTokenURI) external onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

  function setPresale(bool _presaleIsActive) external onlyOwner {
    presaleIsActive = _presaleIsActive;
  }

  function setSale(bool _saleIsActive) external onlyOwner {
    saleIsActive = _saleIsActive;
  }

  function setCollectionSize(uint256 _collectionSize) external onlyOwner {
    collectionSize = _collectionSize;
  }

  function setSigner(address _signer) external onlyOwner {
    signer = _signer;
  }

  function setReveal(bool _reveal) external onlyOwner {
    revealed = _reveal;
  }

  // view function
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    if (!revealed) return baseTokenURI;
    return bytes(baseTokenURI).length != 0 ? string(abi.encodePacked(baseTokenURI, tokenId.toString())) : "";
  }

  function withdraw() public onlyOwner {
    (bool success, ) = msg.sender.call{ value: address(this).balance }("");
    require(success, "Transfer failed.");
  }
}
