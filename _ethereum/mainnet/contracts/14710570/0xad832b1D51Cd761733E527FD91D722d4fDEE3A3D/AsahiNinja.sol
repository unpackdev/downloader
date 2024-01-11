// SPDX-License-Identifier: MIT

// ░█████╗░░██████╗░█████╗░██╗░░██╗██╗███╗░░██╗██╗███╗░░██╗░░░░░██╗░█████╗░
// ██╔══██╗██╔════╝██╔══██╗██║░░██║██║████╗░██║██║████╗░██║░░░░░██║██╔══██╗
// ███████║╚█████╗░███████║███████║██║██╔██╗██║██║██╔██╗██║░░░░░██║███████║
// ██╔══██║░╚═══██╗██╔══██║██╔══██║██║██║╚████║██║██║╚████║██╗░░██║██╔══██║
// ██║░░██║██████╔╝██║░░██║██║░░██║██║██║░╚███║██║██║░╚███║╚█████╔╝██║░░██║
// ╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝╚═╝╚═╝░░╚══╝░╚════╝░╚═╝░░╚═╝

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract AsahiNinja is Ownable, ERC721A, ReentrancyGuard {

  
  string private _baseTokenURI = "";
  string private _unrevealedURI = "ipfs://QmXtQoTH7EEdQgKPyL7h1FGt5ym3h1R58BhQh1LkqHZ552/";

  bytes32 private _rootHash = 0x2b7900c268f2c5e921291afad9852c81a170340583f20d72827b50b1e8e9d6db;
  uint256 public maxWhitelist = 2;
  uint256 public maxPublicSize = 5;
  uint256 public totalCollectionSize = 3535;

  // Reveal Setting
  bool private _isRevealed = false;
  bool private _isPaused = false;
  bool private _publicMintOpen = false;

  // Pricing
  struct SaleConfig {
    uint256 presalePrice;
    uint256 publicPrice;
  }
  SaleConfig public saleConfig;

  // Constructor
  constructor() ERC721A("Asahi Ninja", "ASAHI", maxPublicSize, totalCollectionSize) {
    saleConfig.presalePrice = 0.059 ether;
    saleConfig.publicPrice = 0.059 ether;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function getBalance() external view onlyOwner returns (uint256) {
    return address(this).balance;
  }

  function whitelistMint(uint256 quantity, bytes32[] calldata _merkleProof) external payable callerIsUser {
    require(!_isPaused, "Mint is paused");
    uint256 presalePrice = uint256(saleConfig.presalePrice);
    require(presalePrice > 0, "Presale has not started yet");
    bytes32 _leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, _rootHash, _leaf), "Not eligible for presale mint");
    uint256 ownerMintedCount = balanceOf(msg.sender);
    require(ownerMintedCount + quantity <= maxWhitelist, "Reached max allowed quantity for this address");
    require(totalSupply() + quantity <= collectionSize, "Reached max supply");
    _safeMint(msg.sender, quantity);
    refundIfOver(presalePrice * quantity);
  }

  function publicSaleMint(uint256 quantity) external payable callerIsUser {
    require(!_isPaused, "Mint is paused");
    require(_publicMintOpen, "Public mint is not open yet");
    uint256 publicPrice = uint256(saleConfig.publicPrice);
    require(quantity <= maxBatchSize, "Quantity reached max batch size");
    require(totalSupply() + quantity <= collectionSize, "Reached max supply");
    _safeMint(msg.sender, quantity);
    refundIfOver(publicPrice * quantity);
  }

  // For Senseis and Giveaways
  function airdrop(uint256 quantity, address destination) public onlyOwner  {
    require(quantity > 0, "Mint must be more than 0");
    require(quantity <= maxBatchSize, "Exceded max batch size");
    require(totalSupply() + quantity <= collectionSize, "Max NFT limit exceeded");
    _safeMint(destination, quantity);
  }

  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "Need to send more ETH.");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

  function setPrice(uint64 presalePrice, uint64 publicPrice) external onlyOwner {
    saleConfig.presalePrice = presalePrice;
    saleConfig.publicPrice = publicPrice;
  }

  function isRevealed() external view returns (bool) {
    return _isRevealed;
  }

  function isPaused() external view returns (bool) {
    return _isPaused;
  }

  function togglePause(bool pauseStatus) external onlyOwner {
    _isPaused = pauseStatus;
  }

  function revealNow(string calldata newBaseURI) external onlyOwner {
    _baseTokenURI = newBaseURI;
    _isRevealed = true;
  }

  function openForPublic() external onlyOwner {
    _publicMintOpen = true;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _isRevealed ? _baseTokenURI : _unrevealedURI;
  }

  function setBaseURI(string calldata newBaseURI) external onlyOwner {
    _baseTokenURI = newBaseURI;
  }

  function setUnrevealedURI(string calldata newUnrevealedURI) external onlyOwner {
    _unrevealedURI = newUnrevealedURI;
  }

  function getBatchSize() external view returns (uint256) {
    return maxBatchSize;
  }

  function getCollectionSize() external view returns (uint256) {
    return collectionSize;
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

  function setRoot(bytes32 _root) public onlyOwner  {
    _rootHash = _root;
  }

  function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
    return ownershipOf(tokenId);
  }
}
