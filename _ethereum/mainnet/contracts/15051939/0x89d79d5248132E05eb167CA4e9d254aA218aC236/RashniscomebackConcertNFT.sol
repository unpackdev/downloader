// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721AQueryable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract RashniscomebackConcertNFT is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;
  mapping(bytes32 => uint256) private partnerCodes;
    
  string private uriPrefix = '';
  string private uriSuffix = '.json';
  string private hiddenMetadataUri;
  string private hiddenPrefixUri;
  
  uint256 public cost;
  uint256 public partnerCost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = false;
  bool private singleHidden = false;
  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _partnerCost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri,
    string memory _hiddenPrefixUri,
    string[] memory _partnerCodes
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost,_partnerCost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
    setHiddenPrefixUri(_hiddenPrefixUri);
    addMultipleToPartnerCodes(_partnerCodes);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');
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
      return (singleHidden == false)? string(abi.encodePacked(hiddenPrefixUri, _tokenId.toString(), uriSuffix)) : hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setSingleHidden(bool _state) public onlyOwner {
    singleHidden = _state;
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setRevealedData(bool _state, string memory _uriPrefix) public onlyOwner {
    revealed = _state;
    uriPrefix = _uriPrefix;
  }

  function setCost(uint256 _cost, uint256 _partnerCost) public onlyOwner {
    cost = _cost;
    partnerCost = _partnerCost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setHiddenPrefixUri(string memory _hiddenPrefixUri) public onlyOwner {
    hiddenPrefixUri = _hiddenPrefixUri;
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

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  //partners
  modifier mintPartnerPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= partnerCost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function partnerMint(uint256 _mintAmount, string calldata _pc) public payable mintCompliance(_mintAmount) mintPartnerPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');
    bytes32 pcHash = keccak256(abi.encodePacked(_pc));
    require(partnerCodes[pcHash] > 0,'Incorrect partner code!');
    _safeMint(_msgSender(), _mintAmount);
    partnerCodes[pcHash] = partnerCodes[pcHash] + _mintAmount;
  }

  function addToPartnerCodes(string calldata _pc) external onlyOwner {
    bytes32 pcHash = keccak256(abi.encodePacked(_pc));
    partnerCodes[pcHash] = 1;
  }

  function addMultipleToPartnerCodes(string[] memory _pcs) public onlyOwner {
    require(_pcs.length <= 100, "Provide less codes in one function call");
    bytes32 pcHash;
    for (uint256 i = 0; i < _pcs.length; i++) {
      pcHash = keccak256(abi.encodePacked(_pcs[i]));
      partnerCodes[pcHash] = 1;
    }
  }

  function _mintedByPartner(string calldata partnerCode) public view returns (uint256) {
    bytes32 pcHash = keccak256(abi.encodePacked(partnerCode));
    if(partnerCodes[pcHash] > 0){
      return (partnerCodes[pcHash]-1);
    }
    return 0;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool hs, ) = payable(0x5E7cae8819163d975401d61c14706B167C4D285A).call{value: address(this).balance * 50 / 100}('');
    require(hs);
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }
}