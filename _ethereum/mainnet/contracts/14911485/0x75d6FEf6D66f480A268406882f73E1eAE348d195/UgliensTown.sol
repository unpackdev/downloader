// SPDX-License-Identifier: MIT

/**
____________________/\\\\\\\\\_________/\\\_____/\\\________/\\\\\\\\\\__________________/\\\\\\\\\\\\\\\_         
 __________________/\\\///////\\\___/\\\\\\\___/\\\\\\\____/\\\///////\\\________________\/\\\///////////__        
  _________________/\\\______\//\\\_\/////\\\__/\\\\\\\\\__\///______/\\\_________________\/\\\_____________       
   __/\\\____/\\\__\//\\\_____/\\\\\_____\/\\\_\//\\\\\\\__________/\\\//____/\\/\\\\\\____\/\\\\\\\\\\\\_____     
    _\/\\\___\/\\\___\///\\\\\\\\/\\\_____\/\\\__\//\\\\\__________\////\\\__\/\\\////\\\___\////////////\\\___    
     _\/\\\___\/\\\_____\////////\/\\\_____\/\\\___\//\\\______________\//\\\_\/\\\__\//\\\_____________\//\\\__   
      _\/\\\___\/\\\___/\\________/\\\______\/\\\____\///______/\\\______/\\\__\/\\\___\/\\\__/\\\________\/\\\__  
       _\//\\\\\\\\\___\//\\\\\\\\\\\/_______\/\\\_____/\\\____\///\\\\\\\\\/___\/\\\___\/\\\_\//\\\\\\\\\\\\\/___ 
        __\/////////_____\///////////_________\///_____\///_______\/////////_____\///____\///___\/////////////_____
*/

// u91!3n5 70wn
// https://twitter.com/uglienstown
// http://uglienstown.wtf/

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract UgliensTown is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;
  mapping(address => uint256) public claimAvailable;

  string public uriPrefix = 'https://metadata.uglienstown.wtf/api/';
  string public uriSuffix = '.json';
  string public provenance = 'f2019361079997a481dc6aa69f34fbe87505ea812e14594d3b93513a2857b627';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;
  uint256 public maxPerWallet;
  uint256 public maxFree;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = true;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    uint256 _maxPerWallet,
    uint256 _maxFree,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxPerWallet(_maxPerWallet);
    setMaxFree(_maxFree);
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, '!nv41!d m!n7 4m0un7');
    require(totalSupply() + _mintAmount <= maxSupply, 'm4x 5upp1y 3xc33d');
    require(balanceOf(msg.sender) + _mintAmount <= maxPerWallet, "y0u h4v3 3xc33d3d 7h3 m!n7 1!m!7 p3r w41137");
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'y4 h4v3 n0 3th');
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

  function claimFreeUglien() external nonReentrant {
    require(claimAvailable[msg.sender] < maxFree, '0n1y 0n3 fr33 c14!m p3r w411et');
    require(!paused, '7h3 c0n7r4c7 !5 p4u53d');
    require(msg.sender == tx.origin);
    uint256 balance = balanceOf(msg.sender);

    claimAvailable[msg.sender] += 1;

    if(claimAvailable[msg.sender] <= maxFree && balance >= 1) {
    claimAvailable[msg.sender] += 1;
    }

    uint256 amount = claimAvailable[msg.sender];

    require(totalSupply() + amount <= maxSupply, "83773r 1uck n3x7 7!m3, 501d 0u7");
    require(balanceOf(msg.sender) + amount <= maxPerWallet, "y0u h4v3 3xc33d3d 7h3 m!n7 1!m!7 p3r w411et");

    _safeMint(msg.sender, amount);
  }

  function mint(uint256 _mintAmount) public payable nonReentrant mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, '7h3 c0n7r4c7 !5 p4u53d');

    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId < _currentIndex) {
      TokenOwnership memory ownership = _ownerships[currentTokenId];

      if (!ownership.burned) {
        if (ownership.addr != address(0)) {
          latestOwnerAddress = ownership.addr;
        }

        if (latestOwnerAddress == _owner) {
          ownedTokenIds[ownedTokenIndex] = currentTokenId;

          ownedTokenIndex++;
        }
      }

      currentTokenId++;
    }

    return ownedTokenIds;
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

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setMaxPerWallet(uint256 _maxPerWallet) public onlyOwner {
    maxPerWallet = _maxPerWallet;
  }

  function setMaxFree(uint256 _maxFree) public onlyOwner {
    maxFree = _maxFree;
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

  function setProvenance(string memory _provenance) public onlyOwner {
    provenance = _provenance;
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

  function updateMaxSupply(uint256 _newSupply) external onlyOwner {
      require(_newSupply < maxSupply, "You tried to increase the suppply. Decrease only.");
      maxSupply = _newSupply;
  }

  function tokenBurn(uint256 tokenId) public onlyOwner {   
      _burn(tokenId);
    }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}
