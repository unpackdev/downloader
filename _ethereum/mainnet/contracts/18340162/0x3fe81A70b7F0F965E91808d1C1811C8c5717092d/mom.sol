// SPDX-License-Identifier: MIT
// @author CristianBelli01K

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./Counters.sol";
import "./MerkleProof.sol";

contract MeOnMars is
ERC721,
ReentrancyGuard,
Ownable
{
  using Address for address;
  using Counters for Counters.Counter;

  Counters.Counter private tokensCounter;
  Counters.Counter private airdropTokensCounter;

  uint256 public maxSupply = 220;
  uint256 public airdropSupply = 20;
  uint256 public maxTokensTx = 5;
  uint256 public maxTokensPerAddress = 20;
  uint256 public price = 5 ether;
  uint256 public startTokenId = 1;

  bool public isActive = false;
  bool public isWhitelistActive = false;

  bytes32 private merkleRoot;

  string private baseUri = "ipfs://QmQQ7TgXR7RUDrDwCBq9b5tsbx3NycaMr8QMUHw2Mtechi/";
  string private uriPostfix = ".json";

  mapping(address => uint256) private addressTokens;

  constructor() ERC721("Me on Mars", "MOM") {}

  //NFT URI
  function _baseURI() internal view override returns (string memory) {
    return baseUri;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {

    if (bytes(uriPostfix).length > 0) {
      return string(abi.encodePacked(
        super.tokenURI(tokenId),
        uriPostfix
      ));
    }

    return super.tokenURI(tokenId);
  }

  function setBaseURI(string calldata _baseUri) external onlyOwner {
    baseUri = _baseUri;
  }

  function setPostfixURI(string calldata _uriPostfix) external onlyOwner {
    uriPostfix = _uriPostfix;
  }

  //Start/End Minting
  function setIsActive(bool active) external onlyOwner {
    isActive = active;
  }

  function setAirdropSupply(uint256 _airdropSupply) external onlyOwner {
    require(_airdropSupply <= maxSupply - totalSupplied(), "Inconsistent amount");
    airdropSupply = _airdropSupply;
  }

  function setIsWhitelistActive(bool _isWhitelistActive) external onlyOwner {
    isWhitelistActive = _isWhitelistActive;
  }

  //Whitelist
  function isWhitelistEarlyAccess() public view returns (bool){
    return isWhitelistActive;
  }

  function isWhitelisted(address _address, bytes32[] calldata proof) public view returns (bool){
    bytes32 leaf = keccak256(abi.encodePacked(_address));
    return MerkleProof.verify(proof, merkleRoot, leaf);
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function totalSupplied() public  view returns (uint256){
    return tokensCounter.current();
  }

  function airdropSupplied() public  view returns (uint256){
    return airdropTokensCounter.current();
  }

  function mintedTokens(address _address) public view returns (uint256) {
    return addressTokens[_address];
  }

  function setPrice(uint256 _price) external onlyOwner {
    price = _price;
  }

  function setMaxTokensTx(uint256 _maxTokensTx) external onlyOwner {
    maxTokensTx = _maxTokensTx;
  }

  function setMaxTokensPerAddress(uint256 _maxTokensPerAddress) external onlyOwner {
    maxTokensPerAddress = _maxTokensPerAddress;
  }

  function mint(uint256 tokensCount, bytes32[] calldata proof) external payable nonReentrant {
    require(isActive, "Minting not started");
    if(isWhitelistEarlyAccess()){
      require(isWhitelisted(msg.sender, proof), "Whitelist early access is currently ongoing. You are not in the whitelist");
    }

    require(tokensCount <= maxTokensTx, "You cannot mint more than maxTokensTx tokens at once");

    uint256 tokensPrice = tokensCount * price;
    require(tokensPrice <= msg.value, "Inconsistent amount sent");

    _mintConsecutive(tokensCount, msg.sender);
  }

  function _mintConsecutive(uint256 tokensCount, address to) internal {
    require(totalSupplied() + tokensCount <= maxSupply, "Not enough Tokens left");

    uint256 claimedTokens = addressTokens[to];
    require(claimedTokens + tokensCount <= maxTokensPerAddress, "You are trying to mint more token than the amount allowed for a single address");

    for (uint256 i; i < tokensCount; i++) {
      uint256 tokenId = totalSupplied() + startTokenId;
      _safeMint(to, tokenId);
      tokensCounter.increment();
      addressTokens[to] += 1;
    }
  }

  function airdrop(uint256 tokensCount, address to) external nonReentrant onlyOwner {
    require(airdropSupplied() + tokensCount <= airdropSupply, "Not enough airdrop Tokens left");
    _mintConsecutive(tokensCount, to);
    for (uint256 i; i < tokensCount; i++) {
      airdropTokensCounter.increment();
    }
  }

  // Withdraw
  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    if(balance > 0){
      payable(owner()).transfer(balance);
    }
  }
}