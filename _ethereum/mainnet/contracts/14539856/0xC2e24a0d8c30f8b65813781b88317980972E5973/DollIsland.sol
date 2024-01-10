// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./ECDSA.sol";
import "./Ownable.sol";
import "./Strings.sol";

interface WithdrawalProxy {
  function withdraw(address withdrawAddress, uint256 withdrawAmount) external payable;
}

contract DollIsland is Ownable, ERC721A {
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
  uint256 public reserved;

  string private baseTokenURI;
  bool public revealed;

  WithdrawalProxy public immutable withdrawalProxy;

  mapping(address => uint256) public userToUsedNonce;
  address public signer;

  constructor(address proxyAddress) ERC721A("DollIsland", "DOLL") {
    collectionSize = 5000;
    maxBatchSize = 5;
    saleConfig.presalePrice = 0.06 ether;
    saleConfig.publicPrice = 0.07 ether;

    withdrawalProxy = WithdrawalProxy(proxyAddress);
  }

  modifier noContract() {
    require(tx.origin == msg.sender, "No contract call");
    _;
  }

  function airdropMint(address recipient, uint256 amount) external onlyOwner {
    super._safeMint(recipient, amount);
  }

  function presaleMint(
    uint256 quantity,
    uint256 nonce,
    bytes calldata signature
  ) external payable {
    require(presaleIsActive, "presale is not active");
    require(verifySignature(nonce, signature), "can only mint with whitelist signature");
    require(totalSupply() + quantity <= collectionSize, "max supply reached");
    require(msg.value >= saleConfig.presalePrice * quantity, "insufficient funds");
    require(quantity <= 2, "can at most mint 2");

    super._safeMint(msg.sender, quantity);
  }

  function publicMint(uint256 quantity) external payable noContract {
    require(saleIsActive, "sale is not active");
    require(quantity <= maxBatchSize, "can at most mint 5 token per transaction");
    require(totalSupply() + quantity <= collectionSize, "max supply reached");
    require(msg.value >= saleConfig.publicPrice * quantity, "insufficient funds");

    super._safeMint(msg.sender, quantity);
  }

  function verifySignature(uint256 nonce, bytes calldata signature) internal returns (bool) {
    require(nonce > userToUsedNonce[msg.sender], "nonce has already been used");
    userToUsedNonce[msg.sender] = nonce;
    address recoveredAddress = keccak256(abi.encodePacked(msg.sender, nonce)).toEthSignedMessageHash().recover(signature);
    return (recoveredAddress != address(0) && recoveredAddress == signer);
  }

  // set the contracts for owner
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

  function withdrawFund() external onlyOwner {
    withdrawalProxy.withdraw{ value: address(this).balance }(msg.sender, address(this).balance);
  }
}
