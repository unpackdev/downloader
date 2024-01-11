// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

/*

███    ███  █████  ███████ ██       ██████  
████  ████ ██   ██ ██      ██      ██    ██ 
██ ████ ██ ███████ ███████ ██      ██    ██ 
██  ██  ██ ██   ██      ██ ██      ██    ██ 
██      ██ ██   ██ ███████ ███████  ██████  

*/

//------------------------------------------------------------------------------
// Author: @workslon
//------------------------------------------------------------------------------

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./Counters.sol";

contract UArdiansNFT is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;
  using ECDSA for bytes32;
  using Counters for Counters.Counter;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  Counters.Counter private supply;

  string public uriPrefixStage1 = "";
  string public uriPrefixStage2 = "";
  string public uriPrefixStage3 = "";
  string public uriPrefixStage4 = "";
  string public uriPrefixStage5 = "";
  string public uriPrefixStage6 = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;
  
  uint256 public cost = 0.08 ether;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;

  uint256 public supplyStage1 = 100;
  uint256 public supplyStage2 = 900;
  uint256 public supplyStage3 = 1000;
  uint256 public supplyStage4 = 1000;
  uint256 public supplyStage5 = 2000;
  uint256 public supplyStage6 = 5000;

  uint256 public releasePhase = 1;

  mapping(address => uint256) public mintBalances;

  // --- First drop whitelist
  bool public whitelistMintEnabled = false;
  mapping(address => uint8) private _allowList;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _maxMintAmountPerTx
  ) ERC721A(_tokenName, _tokenSymbol) {
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    uint256 ownerMintedCount = mintBalances[msg.sender];
    require(ownerMintedCount + _mintAmount <= maxMintAmountPerTx, "max NFT per address exceeded");

    _safeMint(_msgSender(), _mintAmount);
    mintBalances[msg.sender] += _mintAmount;
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');

    _safeMint(_msgSender(), _mintAmount);
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function updateRelease(uint256 _releasePhase) external onlyOwner {
    releasePhase = _releasePhase;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setUriPrefixStage1(string memory _uriPrefix) external onlyOwner {
    uriPrefixStage1 = _uriPrefix;
  }

  function setUriPrefixStage2(string memory _uriPrefix) external onlyOwner {
    uriPrefixStage2 = _uriPrefix;
  }

  function setUriPrefixStage3(string memory _uriPrefix) external onlyOwner {
    uriPrefixStage3 = _uriPrefix;
  }

  function setUriPrefixStage4(string memory _uriPrefix) external onlyOwner {
    uriPrefixStage4 = _uriPrefix;
  }

  function setUriPrefixStage5(string memory _uriPrefix) external onlyOwner {
    uriPrefixStage5 = _uriPrefix;
  }

  function setUriPrefixStage6(string memory _uriPrefix) external onlyOwner {
    uriPrefixStage6 = _uriPrefix;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function numAvailableToMint(address addr) external view returns (uint8) {
      return _allowList[addr];
  }

  function withdraw() external payable onlyOwner {
    // PrytulaFoundation
    (bool pf, ) = payable(0x858fa9c4De5f7A0e7d6EACB671C3482665A543B2).call{value: address(this).balance * 45 / 100}("");
    require(pf);

    // RazomForUkraine
    (bool rfua, ) = payable(0xA4166BC4Be559b762B346CB4AAad3b051E584E39).call{value: address(this).balance * 45 / 100}("");
    require(rfua);

    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= getMaxSupply()) {
      address currentTokenOwner = ownerOf(currentTokenId);
      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;
        ownedTokenIndex++;
      }
      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function getMaxSupply() public view returns(uint256) {
    return 
      releasePhase == 1 ? supplyStage1 :
      releasePhase == 2 ? supplyStage1 + supplyStage2 :
      releasePhase == 3 ? supplyStage1 + supplyStage2 + supplyStage3 :
      releasePhase == 4 ? supplyStage1 + supplyStage2 + supplyStage3 + supplyStage4 : 
      releasePhase == 5 ? supplyStage1 + supplyStage2 + supplyStage3 + supplyStage4 + supplyStage5 : 
      releasePhase == 6 ? supplyStage1 + supplyStage2 + supplyStage3 + supplyStage4 + supplyStage5 + supplyStage6 : 
      0;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    uint256 stage = _tokenId <= supplyStage1 ? 1 :
      _tokenId <= supplyStage2 + supplyStage1 ? 2 :
      _tokenId <= supplyStage3 + supplyStage2 + supplyStage1 ? 3 :
      _tokenId <= supplyStage4 + supplyStage3 + supplyStage2 + supplyStage1 ? 4 :
      _tokenId <= supplyStage5 + supplyStage4 + supplyStage3 + supplyStage2 + supplyStage1 ? 5 :
      _tokenId <= supplyStage6 + supplyStage5 + supplyStage4 + supplyStage3 + supplyStage2 + supplyStage1 ? 6 :
      0;

    string memory currentBaseURI =  stage == 1 ? uriPrefixStage1 :
      stage == 2 ? uriPrefixStage2 :
      stage == 3 ? uriPrefixStage3 :
      stage == 4 ? uriPrefixStage4 :
      stage == 5 ? uriPrefixStage5 :
      " ";

    return bytes(currentBaseURI).length > 0
      ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
      : "";
  }

  // --- helpers

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(supply.current() + _mintAmount <= getMaxSupply(), 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }
}