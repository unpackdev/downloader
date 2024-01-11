// SPDX-License-Identifier: MIT
// @author CristianBelli01K

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./Counters.sol";
import "./MerkleProof.sol";

contract JoinTheRevolutionKromin is
ERC721,
ReentrancyGuard,
Ownable
{
  using Address for address;
  using Counters for Counters.Counter;

  Counters.Counter private tokensCounter;

  uint256 public maxSupply = 69;
  uint256 public maxTokensTx = 5;
  uint256 public maxTokensPerAddress = 5;
  uint256 public price = 0.0069 ether;
  uint256 public startTokenId = 1;

  bool public isActive;

  string private baseUri = "ipfs://QmfApprcUArypNL1VFTsEvj7KgqSYbTpEcMB6Y5RmviTdw/";
  string private uriPostfix = ".json";

  mapping(address => uint256) private addressTokens;

  bytes32 public merkleRoot = 0x4afe7b08a14365ce940434bbeb5e5c5e1e6f0f9c90dfe111b617ad5b97fc92bd;

  constructor() ERC721("Join the Revolution - Kromin", "JTRK") {}

  // Get Functions
  function mintedTokens(address _address) public view returns (uint256) {
    return addressTokens[_address];
  }

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

  function totalSupply() public view returns (uint256) {
    return tokensCounter.current();
  }

  function isWhitelisted(address _address, bytes32[] calldata proof) public view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(_address));
    return MerkleProof.verify(proof, merkleRoot, leaf);
  }

  // Set Functions
  function setBaseURI(string calldata _baseUri) external onlyOwner {
    baseUri = _baseUri;
  }

  function setPostfixURI(string calldata _uriPostfix) external onlyOwner {
    uriPostfix = _uriPostfix;
  }

  function setPrice(uint256 _price) external onlyOwner {
    price = _price;
  }

  function setIsActive() external onlyOwner {
    isActive = !isActive;
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setMaxTokensTx(uint256 _maxTokensTx) external onlyOwner {
    maxTokensTx = _maxTokensTx;
  }

  function setMaxTokensPerAddress(uint256 _maxTokensPerAddress) external onlyOwner {
    maxTokensPerAddress = _maxTokensPerAddress;
  }

  // Minting functions
  function _mintConsecutive(uint256 tokensCount, address to) internal {
    require(tokensCounter.current() + tokensCount <= maxSupply, "Not enough Tokens left");
    claimTokens(tokensCount);

    for (uint256 i; i < tokensCount; i++) {
      uint256 tokenId = tokensCounter.current() + startTokenId;
      tokensCounter.increment();
      _safeMint(to, tokenId);
    }
  }

  function mint(uint256 tokensCount, bytes32[] calldata proof) external payable nonReentrant {
    require(isActive, "Minting not started");
    require(tokensCount <= maxTokensTx, "You cannot mint more than maxTokensTx tokens at once");

    uint256 tokensPrice = tokensCount * price;
    uint256 claimedTokens = addressTokens[msg.sender];
    if(claimedTokens == 0 && isWhitelisted(msg.sender, proof)){
      tokensPrice = tokensPrice - price;
    }

    require(tokensPrice <= msg.value, "Inconsistent amount sent");

    _mintConsecutive(tokensCount, msg.sender);
  }

  function airdrop(address to) external nonReentrant onlyOwner {
    _mintConsecutive(1, to);
  }

  function claimTokens(uint256 tokensCount) internal {
    uint256 claimedTokens = addressTokens[msg.sender];
    require(claimedTokens + tokensCount <= maxTokensPerAddress, "Can't mint more than allocated");
    addressTokens[msg.sender] = claimedTokens + tokensCount;
  }

  // Withdraw
  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    if(balance > 0){
      payable(owner()).transfer(balance);
    }
  }
}
