// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";

import "./Pausable.sol";
import "./ReentrancyGuard.sol";

import "./Ownable.sol";

import "./Strings.sol";
import "./MerkleProof.sol";

contract AbstractRealm is
  ERC721A,
  Pausable,
  Ownable,
  ReentrancyGuard
{
  uint256 public maxTokens = 1000;

  bytes32 public whitelistMerkleRoot;
  uint256 public whitelistedMinted;
  uint256 public maxWhitelistTokens = 250;
  uint256 public whitelistSalePrice = 0;
  mapping(address => bool) public whitelistClaimed;

  uint256 public publicSalePrice = 0.0077 ether;
  mapping(address => uint256) public publicClaimed;
  uint256 public maxTokensPerUser = 5;

  uint256 public saleStartingTime;
  string public baseURL;

  bool public isRevealed;
  string public unRevealedMetadataURL;

  constructor(uint256 _saleStartingTime) ERC721A("AbstractRealm", "AR") {
    saleStartingTime = _saleStartingTime;
    _mint(msg.sender, 50);
  }

  modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
    require(
      MerkleProof.verify(
        merkleProof,
        root,
        keccak256(abi.encodePacked(msg.sender))
      ),
      "Address does not exist in list"
    );
    _;
  }

  modifier canMint(uint256 numberOfTokens) {
    require(
      (totalSupply() + numberOfTokens) <= maxTokens,
      "Not enough tokens remaining to mint"
    );
    _;
  }

  modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
    require(msg.value >= (price * numberOfTokens), "Not Enough ETH");
    _;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURL;
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  function whitelistMint(bytes32[] calldata merkleProof)
    external
    payable
    isValidMerkleProof(merkleProof, whitelistMerkleRoot)
    isCorrectPayment(whitelistSalePrice, 1)
    canMint(1)
    whenNotPaused
    nonReentrant
  {
    require(
      whitelistedMinted < maxWhitelistTokens,
      "Minted the maximum # of whitelist tokens"
    );
    require(
      !whitelistClaimed[msg.sender],
      "NFT is already claimed by this wallet"
    );

    _mint(msg.sender, 1);
    whitelistClaimed[msg.sender] = true;
    whitelistedMinted++;
  }

  function publicMint(uint256 numberOfTokens)
    external
    payable
    whenNotPaused
    isCorrectPayment(publicSalePrice, numberOfTokens)
    canMint(numberOfTokens)
    nonReentrant
  {
    require(saleStartingTime < block.timestamp, "Sale has not started yet");
    require(numberOfTokens <= maxTokensPerUser, "Maximum Minting Limit Exceeded");
    require(
      (publicClaimed[msg.sender] + numberOfTokens) <= maxTokensPerUser,
      "Maximum Minting Limit Exceeded"
    );

    _mint(msg.sender, numberOfTokens);
    publicClaimed[msg.sender] += numberOfTokens;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (isRevealed == false) {
      return unRevealedMetadataURL;
    }

    string memory currentBaseURI = _baseURI();
    return
      bytes(currentBaseURI).length > 0
        ? string(
          abi.encodePacked(currentBaseURI, Strings.toString(_tokenId), ".json")
        )
        : "";
  }

  function setBaseURL(string memory _baseURL) external onlyOwner {
    baseURL = _baseURL;
  }

  function setWhitelistSalePrice(uint256 _price) external onlyOwner {
    whitelistSalePrice = _price;
  }

  function setPublicSalePrice(uint256 _price) external onlyOwner {
    publicSalePrice = _price;
  }

  function setSaleStartingTime(uint256 _saleStartingTime) external onlyOwner {
    saleStartingTime = _saleStartingTime;
  }

  function setIsRevealed(bool _isRevealed) external onlyOwner {
    isRevealed = _isRevealed;
  }

  function setUnRevealedMetadataURL(string memory _unRevealedMetadataURL)
    external
    onlyOwner
  {
    unRevealedMetadataURL = _unRevealedMetadataURL;
  }

  function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    whitelistMerkleRoot = merkleRoot;
  }

  function withdraw() external onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}