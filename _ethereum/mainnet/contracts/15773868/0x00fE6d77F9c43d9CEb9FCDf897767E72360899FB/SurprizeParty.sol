// SPDX-License-Identifier: MIT
/*
/ 
   _____                       _          
  / ____|                     (_)         
 | (___  _   _ _ __ _ __  _ __ _ _______  
  \___ \| | | | '__| '_ \| '__| |_  / _ \ 
  ____) | |_| | |  | |_) | |  | |/ /  __/ 
 |_____/ \__,_|_| _| .__/|_|  |_/___\___| 
 |  __ \         | | |                    
 | |__) |_ _ _ __| |_|_   _               
 |  ___/ _` | '__| __| | | |              
 | |  | (_| | |  | |_| |_| |              
 |_|   \__,_|_|   \__|\__, |              
                       __/ |              
                      |___/               
 */
// @author: lloyd.lens
// https://www.birthday.wtf

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721AQueryable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract SurprizeParty is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;
  uint256 public totalMaxMintAmount = 2; 
  uint256 public freeMaxMintAmount = 0; 

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

  mapping(address => uint256) public addressMintedBalance;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
    ownerMint(44);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    if (msg.sender != owner()) {
      require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    }
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    uint256 ownerMintedCount = addressMintedBalance[msg.sender];
    if (ownerMintedCount >= freeMaxMintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    }
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');
    uint256 ownerMintedCount = addressMintedBalance[msg.sender];

    if (ownerMintedCount < freeMaxMintAmount) {
        require(ownerMintedCount + _mintAmount <= freeMaxMintAmount, "Exceeded Free Mint Limit");
          } else if (ownerMintedCount >= freeMaxMintAmount) { 
              require(ownerMintedCount + _mintAmount <= totalMaxMintAmount, "Exceeded Mint Limit");
          }
        _safeMint(_msgSender(), _mintAmount);
        for (uint256 i = 1; i <=_mintAmount; i++){
          addressMintedBalance[msg.sender]++;
      }
  }


  function ownerMint(uint256 _mintAmount) public payable onlyOwner {
     require(_mintAmount > 0, 'Invalid mint amount!');
     require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
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
    cost = _cost;
  }

  function setFreeMaxMintAmount(uint256 _freeMaxMintAmount) public onlyOwner {
    freeMaxMintAmount = _freeMaxMintAmount; 
  }

  function setTotalMaxMintAmount(uint _amount) public onlyOwner {
      require(_amount <= maxSupply, "Exceed total amount");
      totalMaxMintAmount = _amount;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
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

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}