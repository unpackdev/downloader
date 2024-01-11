// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";


/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                         //
//     ______     ______     ______      ______   __         ______     __   __     ______     ______      //
//    /\  ___\   /\  __ \   /\__  _\    /\  == \ /\ \       /\  __ \   /\ "-.\ \   /\  ___\   /\__  _\     //
//    \ \ \____  \ \  __ \  \/_/\ \/    \ \  _-/ \ \ \____  \ \  __ \  \ \ \-.  \  \ \  __\   \/_/\ \/     //
//     \ \_____\  \ \_\ \_\    \ \_\     \ \_\    \ \_____\  \ \_\ \_\  \ \_\\"\_\  \ \_____\    \ \_\     //
//      \/_____/   \/_/\/_/     \/_/      \/_/     \/_____/   \/_/\/_/   \/_/ \/_/   \/_____/     \/_/     //
//                                                                                                         //
//                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CatPlanet is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;
  mapping(address => bool) public publicClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public maxSupply;
  uint256 public publicMintCost;
  uint256 public whitelistMintCost;
  uint256 public maxMintAmountPerTx;

  bool public publicMintEnabled = false;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

  constructor(
    uint256 _maxSupply,
    uint256 _whitelistMintCost,
    uint256 _publicMintCost,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri,
    string memory _uriPrefix
  ) ERC721A("CatPlanet", "CAT") {
    maxSupply = _maxSupply;
    whitelistMintCost = _whitelistMintCost;
    publicMintCost = _publicMintCost;
    maxMintAmountPerTx = _maxMintAmountPerTx;
    setHiddenMetadataUri(_hiddenMetadataUri);
    setUriPrefix(_uriPrefix);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier whitelistMintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= whitelistMintCost * _mintAmount, 'Insufficient funds!');
    _;
  }

  modifier publicMintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= publicMintCost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) whitelistMintPriceCompliance(_mintAmount) {
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) publicMintPriceCompliance(_mintAmount) {
    require(publicMintEnabled, 'The public sale is not enabled!');
    require(!publicClaimed[_msgSender()], 'Address already claimed!');

    publicClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _safeMint(_receiver, _mintAmount);
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

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
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

  function setPublicMintCost(uint256 _cost) public onlyOwner {
    publicMintCost = _cost;
  }

  function setWhitelistMintCost(uint256 _cost) public onlyOwner {
    whitelistMintCost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function setPublicMintEnabled(bool _state) public onlyOwner {
    publicMintEnabled = _state;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }
}