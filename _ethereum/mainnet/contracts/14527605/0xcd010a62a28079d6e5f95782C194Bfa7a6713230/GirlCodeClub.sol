// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract GirlCodeClub is ERC721A, Ownable, ReentrancyGuard{

  using Strings for uint256;

  bytes32 public merkleRootLVL1;
  bytes32 public merkleRootFreeMint;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerWallet;
  uint256 public withholdAmount;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;
  
  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerWallet,
    string memory _hiddenMetadataUri,
    uint256 _withholdAmount
  ) ERC721A(_tokenName, _tokenSymbol) {
    cost = _cost;
    maxSupply = _maxSupply;
    maxMintAmountPerWallet = _maxMintAmountPerWallet;
    withholdAmount = _withholdAmount;
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier mintCompliance(uint256 _mintAmount, address _owner) {
    require(_mintAmount > 0, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount + withholdAmount <= maxSupply, 'Max supply exceeded!');
    require(balanceOf(_owner) + _mintAmount <= maxMintAmountPerWallet, 'Maximum tokens in wallet exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof, address _owner) public payable mintCompliance(_mintAmount, _owner) {

    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRootLVL1, leaf) || MerkleProof.verify(_merkleProof, merkleRootFreeMint, leaf), 'Invalid proof!');

    uint256 wlVersion;
    wlVersion = whitelistversion(leaf, _merkleProof);

    if (wlVersion == 1) {
      require(msg.value >= cost * _mintAmount, 'Insufficient funds! You probably have the free mint box ticked, try unticking it!');
      _safeMint(_msgSender(), _mintAmount);
    }

    if (wlVersion == 2) {

      if (whitelistClaimed[_msgSender()] = false) {
        require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
      }

      else {
        require(!whitelistClaimed[_msgSender()], 'Your free mint has already been used!');
        require(msg.value >= cost * (_mintAmount-1), 'You have 1 unclaimed free mint, make sure to tick the free mint box and try again!');
        _safeMint(_msgSender(), _mintAmount);
        whitelistClaimed[_msgSender()] = true;
      }
    }
  }

  function whitelistversion(bytes32 _leaf, bytes32[] calldata _merkleProof) public view returns (uint256){

    uint256 whitelistVersion;

    if (MerkleProof.verify(_merkleProof, merkleRootLVL1, _leaf) == true) {
      whitelistVersion = 1;
    }

    if (MerkleProof.verify(_merkleProof, merkleRootFreeMint, _leaf) == true) {
      whitelistVersion = 2;
    }

    return whitelistVersion;

  }

  function mint(uint256 _mintAmount, address _owner) public payable mintCompliance(_mintAmount, _owner) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');
    _safeMint(_msgSender(), _mintAmount);
  }

  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount, _receiver) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function mintFromWithheld(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount, _receiver) onlyOwner {
    _safeMint(_receiver, _mintAmount);
    withholdAmount = withholdAmount - _mintAmount;
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      TokenOwnership memory ownership = _ownerships[currentTokenId];

      if (!ownership.burned && ownership.addr != address(0)) {
        latestOwnerAddress = ownership.addr;
      }

      if (latestOwnerAddress == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
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

  function setMaxMintAmountPerWallet(uint256 _maxMintAmountPerWallet) public onlyOwner {
    maxMintAmountPerWallet = _maxMintAmountPerWallet;
  }

  function setwithholdAmount(uint256 _withholdAmount) public onlyOwner {
    withholdAmount = _withholdAmount;
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

  function setMerkleRootLVL1(bytes32 _merkleRoot) public onlyOwner {
    merkleRootLVL1 = _merkleRoot;
  }

  function setMerkleRootFreeMint(bytes32 _merkleRoot) public onlyOwner {
    merkleRootFreeMint = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function withdraw() public onlyOwner nonReentrant {
 
    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}
