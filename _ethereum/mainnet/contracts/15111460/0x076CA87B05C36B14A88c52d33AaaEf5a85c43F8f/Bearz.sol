// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

contract Bearz is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
 
  uint256 public maxSupply = 3333;
  uint256 public maxPublicMintAmountPerTx = 2;
  uint256 public maxGuardianMintAmountPerWallet = 2;
  uint256 public maxSentinelMintAmountPerWallet = 2;

  uint256 public publicMintCost = 0.14 ether;
  uint256 public publicDiscount = 0.13 ether;
  uint256 public whitelistDiscount = 0.09 ether; 
  uint256 public guardianMintCost = 0.099 ether;
  uint256 public sentinelMintCost = 0.099 ether;

  bytes32 public merkleRoot1;
  bytes32 public merkleRoot2;
  bool public paused = true;
  bool public guardianMintEnabled = false;
  bool public sentinelMintEnabled = false;
  bool public revealed = false;

  constructor(
      string memory _tokenName, 
      string memory _tokenSymbol, 
      string memory _hiddenMetadataUri)  ERC721A(_tokenName, _tokenSymbol)  {
    hiddenMetadataUri = _hiddenMetadataUri;       
    ownerClaimed();
   
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  function ownerClaimed() internal {
    _mint(_msgSender(), 150);
  }

  function guardianMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) {
    // Verification for guardian mint.
    require(guardianMintEnabled, 'The Guardian sale is not enabled!');
    require(_numberMinted(_msgSender()) + _mintAmount <= maxGuardianMintAmountPerWallet, 'Max limit per wallet!');
    if (_mintAmount > 1) {
      require(msg.value >= whitelistDiscount * _mintAmount, 'Insufficient funds for Guardian!');
    }
    else {
      require(msg.value >= guardianMintCost * _mintAmount, 'Insufficient funds for Guardian!');
    }
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot1, leaf), 'Invalid proof for Guardian!');

    _safeMint(_msgSender(), _mintAmount);
  }

  function sentinelMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) {
    // Verification for sentinel mint.
    require(sentinelMintEnabled, 'The Sentinel sale is not enabled!');
    require(_numberMinted(_msgSender()) + _mintAmount <= maxSentinelMintAmountPerWallet, 'Max limit per wallet!');
    if (_mintAmount > 1) {
      require(msg.value >= whitelistDiscount * _mintAmount, 'Insufficient funds for Sentinel!');
    }
    else {
      require(msg.value >= sentinelMintCost * _mintAmount, 'Insufficient funds for Sentinel!');
    }
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot2, leaf), 'Invalid proof for Sentinel!');

    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) nonReentrant {
    require(!paused, 'The mint is paused!');
    require(_mintAmount <= maxPublicMintAmountPerTx, 'Max limited per Transaction!');
    if (_mintAmount > 1) {
      require(msg.value >= publicDiscount * _mintAmount, 'Insufficient funds for public sale!');
    }
    else {
      require(msg.value >= publicMintCost * _mintAmount, 'Insufficient funds for public sale!');
    }
    _safeMint(_msgSender(), _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    publicMintCost = _cost;
  }

  function setPublicDiscountCost(uint256 _cost) public onlyOwner { 
    publicDiscount = _cost;
  }

  function setWhitelistDiscount(uint256 _cost) public onlyOwner{
    whitelistDiscount = _cost;
    
  }

  function setGuardianCost(uint256 _cost) public onlyOwner {
    guardianMintCost = _cost;
  }

  function setSentinelCost(uint256 _cost) public onlyOwner {
    sentinelMintCost = _cost;
  }

  function setMaxPublicMintAmountPerTx(uint256 _maxPublicMintAmountPerTx) public onlyOwner {
    maxPublicMintAmountPerTx = _maxPublicMintAmountPerTx;
  }

  function setMaxGuardianMintAmountPerWallet(uint256 _maxGuardianMintAmountPerWallet) public onlyOwner {
    maxGuardianMintAmountPerWallet = _maxGuardianMintAmountPerWallet;
  }

  function setMaxSentinelMintAmountPerWallet(uint256 _maxSentinelMintAmountPerWallet) public onlyOwner {
    maxSentinelMintAmountPerWallet = _maxSentinelMintAmountPerWallet;
  }


  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setMerkleRoot1(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot1 = _merkleRoot;
  }

  function setMerkleRoot2(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot2 = _merkleRoot;
  }

  function setGuardianMintEnabled(bool _state) public onlyOwner {
    guardianMintEnabled = _state;
  }

  function setSentinelMintEnabled(bool _state) public onlyOwner {
    sentinelMintEnabled = _state;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function withdraw() public onlyOwner {
  
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}
