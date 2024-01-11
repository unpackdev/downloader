// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract TaggerzXL is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;
  mapping(address => bool) public alreadyMinted;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public maxSupply;
  uint256 public randomResult;

  bool public paused = true;
  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _maxSupply,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    maxSupply = _maxSupply;
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier totalSupplyCompliance(uint256 _mintAmount) {
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }
  
  function randomNumber() internal view onlyOwner returns(uint){
    return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  
      msg.sender))) % maxSupply;
  }

  function mint() public totalSupplyCompliance(1) nonReentrant {
    require(!paused, 'The contract is paused!');
    require(alreadyMinted[msg.sender] == false, 'Address already used');

    _safeMint(_msgSender(), 1);

    alreadyMinted[msg.sender] = true;
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner totalSupplyCompliance(_mintAmount) {
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

    if(_tokenId + randomResult <= maxSupply) {
        return bytes(currentBaseURI).length > 0
             ? string(abi.encodePacked(currentBaseURI, (_tokenId + randomResult).toString(), uriSuffix))
             : '';
    }
    else {
        return bytes(currentBaseURI).length > 0
             ? string(abi.encodePacked(currentBaseURI, (_tokenId - (maxSupply - randomResult)).toString(), uriSuffix))
             : '';
    }
  }

  function setRevealed() public onlyOwner {
    require(revealed == false, "collection is already revealed!");
    randomResult = randomNumber();
    revealed = true;
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

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}
