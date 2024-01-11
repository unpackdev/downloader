// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./Strings.sol";

contract MidnightClash is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;
  using ECDSA for bytes32;
  uint256 public immutable collectionSize;

  mapping(address => uint256) public whitelistUsed;
  mapping(address => uint256) public publicMinted;
  bool public _isWhitelistSaleActive = true;
  bool public _isSaleActive = true;
  address private _whitelistAndPublicSigner = 0x6a389354957955Bef004222B3dBF4FAb40Ace650;

  constructor(uint256 collectionSize_) ERC721A("MidnightClash", "MNC") {
    collectionSize = collectionSize_;
  }
  function flipWhitelistSaleActive() public onlyOwner {
    _isWhitelistSaleActive = !_isWhitelistSaleActive;
  }

  function flipSaleActive() public onlyOwner {
    _isSaleActive = !_isSaleActive;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function whitelistMint(bytes32 hash, bytes calldata signature, uint256 limit, uint256 quantity) external payable callerIsUser {
    require(_isWhitelistSaleActive, "Whitelist Sale has not begin");
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(matchAddresSigner(hash, signature, _whitelistAndPublicSigner), "DIRECT_MINT_DISALLOWED");
    require(hashTransactionLimit(msg.sender, quantity, limit) == hash, "HASH_FAIL");
    require(whitelistUsed[msg.sender] + quantity <= limit, "Quantity is over limit");
    _safeMint(msg.sender, quantity);
    whitelistUsed[msg.sender] += quantity;
  }

  function publicSaleMint(bytes32 hash, bytes calldata signature, uint256 quantity) external payable callerIsUser {
    require(_isSaleActive, "Public sale has not begin");
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(matchAddresSigner(hash, signature, _whitelistAndPublicSigner), "DIRECT_MINT_DISALLOWED");
    require(hashTransaction(msg.sender, quantity) == hash, "HASH_FAIL");
    require(publicMinted[msg.sender] + quantity <= 2, "Quantity is over limit");
    _safeMint(msg.sender, quantity);
    publicMinted[msg.sender] += quantity;
  }

  // For marketing etc.
  function devMint(uint256 quantity, address to) external onlyOwner {
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    _safeMint(to, quantity);
  }

  function hashTransaction(address sender, uint256 qty) private pure returns(bytes32) {
    bytes32 hash = keccak256(abi.encodePacked(
      "\x19Ethereum Signed Message:\n32",
      keccak256(abi.encodePacked(sender, qty)))
    );
    return hash;
  }

  function hashTransactionLimit(address sender, uint256 qty, uint256 limit) private pure returns(bytes32) {
    bytes32 hash = keccak256(abi.encodePacked(
      "\x19Ethereum Signed Message:\n32",
      keccak256(abi.encodePacked(sender, qty, limit)))
    );
    return hash;
  }
  
  function matchAddresSigner(bytes32 hash, bytes memory signature, address _signerAddress) private pure returns(bool) {
    return _signerAddress == hash.recover(signature);
  }

  // // metadata URI
  string private _baseTokenURI;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function withdraw(address to) external onlyOwner nonReentrant {
    uint256 balance = address(this).balance;
    payable(to).transfer(balance);
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return _ownershipOf(tokenId);
  }
}
